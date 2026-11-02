# Install NixOS from the dotfiles flake: reinstall an existing host on a new
# disk, or create a new host from a type profile (nixos.<type>Profile).
# Usage: install-host [disk] [swap-GiB]
# Wrapped by writeShellApplication (hosts/live-iso/install-host.nix), which
# adds the shebang, `set -euo pipefail` and PATH.

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

DISK=${1:-}
SWAP_GIB=${2:-16}
DOTFILES_DIR=/tmp/dotfiles
DOTFILES_REPO=https://github.com/erik-sundin-git/dotfiles.git
HOSTS_DIR="$DOTFILES_DIR/nix/modules/hosts"
TOPOLOGY="$HOSTS_DIR/topology.nix"
TOPOLOGY_ANCHOR="# install-host inserts new hosts above this line"
HW_CONF=/mnt/etc/nixos/hardware-configuration.nix
# Must match the nixos.<type>Profile names in hosts/common/nixos/profiles.nix
TYPES=(laptop desktop server vm)

if [[ ! "$SWAP_GIB" =~ ^[1-9][0-9]*$ ]]; then
  echo "Swap size must be a whole number of GiB: $SWAP_GIB"; exit 1
fi

# On failure after mounting, release /mnt and the swap partition so the script
# can simply be run again (it repartitions from scratch).
MOUNTED=0
cleanup() {
  local rc=$?
  if ((rc != 0 && MOUNTED)); then
    echo ""
    echo "install-host failed (exit $rc); unmounting /mnt and disabling swap."
    umount -R /mnt 2>/dev/null || true
    swapoff "${SWAP_DEV:-}" 2>/dev/null || true
    echo "Fix the problem and run install-host again. A new host that was"
    echo "already registered is now offered under 'Reinstall'."
  fi
}
trap cleanup EXIT

# ── Dotfiles ─────────────────────────────────────────────────────────────
# Cloned first: the host menu is read from topology.nix.

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  echo "Cloning dotfiles..."
  git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR" || {
    echo "Clone failed. No network? Connect with nmtui and try again."
    exit 1
  }
fi

# nix/secrets/hosts.nix is git-crypt encrypted and evaluated by every host,
# so nothing can be installed from a locked repo.
repo_locked() {
  [[ "$(head -c 9 "$DOTFILES_DIR/nix/secrets/hosts.nix" | tr -d '\0')" == GITCRYPT ]]
}
if repo_locked; then
  read -rp "Path to git-crypt key (e.g. a USB stick): " CRYPT_KEY
  if [[ -n "$CRYPT_KEY" ]]; then
    git -C "$DOTFILES_DIR" crypt unlock "$CRYPT_KEY"
  fi
  if repo_locked; then
    echo "The repo is still locked; every host evaluates nix/secrets/hosts.nix. Aborting."
    exit 1
  fi
fi

# ── Host selection ───────────────────────────────────────────────────────

mapfile -t HOSTS < <(grep -oP 'den\.hosts\.x86_64-linux\.\K[a-z0-9-]+' "$TOPOLOGY")

echo ""
echo "Reinstall an existing host:"
for i in "${!HOSTS[@]}"; do
  printf "  %d) %s\n" "$((i + 1))" "${HOSTS[$i]}"
done
echo "Or create a new host:"
for i in "${!TYPES[@]}"; do
  printf "  %d) new %s\n" "$((${#HOSTS[@]} + i + 1))" "${TYPES[$i]}"
done
echo ""
read -rp "Choice: " CHOICE

if [[ ! "$CHOICE" =~ ^[0-9]+$ ]]; then
  echo "Invalid choice: $CHOICE"; exit 1
fi
CHOICE=$((10#$CHOICE)) # "08" would otherwise be read as bad octal
if ((CHOICE < 1 || CHOICE > ${#HOSTS[@]} + ${#TYPES[@]})); then
  echo "Invalid choice: $CHOICE"; exit 1
fi

if ((CHOICE <= ${#HOSTS[@]})); then
  INSTALL_HOST=${HOSTS[$((CHOICE - 1))]}
  HOST_TYPE=""
else
  HOST_TYPE=${TYPES[$((CHOICE - ${#HOSTS[@]} - 1))]}
  read -rp "Hostname for the new $HOST_TYPE: " INSTALL_HOST
  if [[ ! "$INSTALL_HOST" =~ ^[a-z][a-z0-9-]*$ || -e "$HOSTS_DIR/$INSTALL_HOST" ]]; then
    echo "Invalid or existing hostname: $INSTALL_HOST"; exit 1
  fi
fi
HOST_DIR="$HOSTS_DIR/$INSTALL_HOST"

# The layout follows how the ISO was booted: UEFI gets an ESP for
# systemd-boot, legacy BIOS gets a bios_grub partition for GRUB on GPT.
if [[ -d /sys/firmware/efi ]]; then EFI=1; else EFI=0; fi

# An existing host must evaluate, and its bootloader must match the firmware
# mode, before anything is wiped.
if [[ -z "$HOST_TYPE" ]]; then
  echo "Evaluating $INSTALL_HOST..."
  if ! nix eval --raw "$DOTFILES_DIR#nixosConfigurations.$INSTALL_HOST.config.system.build.toplevel.drvPath" >/dev/null; then
    echo "$INSTALL_HOST does not evaluate; fix the flake first. Nothing was changed."
    exit 1
  fi
  HOST_EFI=$(nix eval --raw "$DOTFILES_DIR#nixosConfigurations.$INSTALL_HOST.config.commonConfig.bootEFI" \
    --apply 'efi: if efi then "1" else "0"')
  if [[ "$HOST_EFI" != "$EFI" ]]; then
    echo "$INSTALL_HOST is configured for $( ((HOST_EFI)) && echo UEFI || echo BIOS ) boot, but the ISO"
    echo "was booted in $( ((EFI)) && echo UEFI || echo BIOS ) mode. Reboot the ISO in the matching mode."
    exit 1
  fi
fi

# ── Disk setup ───────────────────────────────────────────────────────────

ISO_DISK=
ISO_SRC=$(findmnt -no SOURCE /iso 2>/dev/null || true)
if [[ -n "$ISO_SRC" ]]; then
  ISO_DISK=$(lsblk -no PKNAME "$ISO_SRC" 2>/dev/null | head -n1 || true)
  if [[ -z "$ISO_DISK" ]]; then ISO_DISK=$(basename "$ISO_SRC"); fi
fi

if [[ -z "$DISK" ]]; then
  # Suggest the largest fixed disk that isn't the installer medium or in use
  DEFAULT_DISK=
  DEFAULT_SIZE=0
  while read -r NAME SIZE RM; do
    if [[ "$NAME" == /dev/zram* || "$RM" == 1 || "$(basename "$NAME")" == "$ISO_DISK" ]]; then
      continue
    fi
    if lsblk -nro MOUNTPOINT "$NAME" | grep -q .; then continue; fi
    if ((SIZE > DEFAULT_SIZE)); then DEFAULT_DISK=$NAME; DEFAULT_SIZE=$SIZE; fi
  done < <(lsblk -dpnbo NAME,SIZE,RM -e 7,11)

  echo ""
  lsblk -d -e 7,11 -o NAME,SIZE,MODEL
  if [[ -n "$DEFAULT_DISK" ]]; then
    read -rp "Disk to install to [$DEFAULT_DISK]: " DISK
    DISK=${DISK:-$DEFAULT_DISK}
  else
    read -rp "Disk to install to (e.g. /dev/nvme0n1): " DISK
  fi
fi
# Resolve /dev/disk/by-id/... links so partition names can be derived
DISK=$(readlink -f "$DISK")
if [[ ! -b "$DISK" || "$(lsblk -dno TYPE "$DISK")" != disk ]]; then
  echo "$DISK is not a whole disk"; exit 1
fi

if [[ -n "$ISO_DISK" && "$(basename "$DISK")" == "$ISO_DISK" ]]; then
  echo "$DISK is the installer medium"; exit 1
fi
if lsblk -nro MOUNTPOINT "$DISK" | grep -q .; then
  echo "$DISK has mounted partitions or active swap:"
  lsblk -o NAME,MOUNTPOINT "$DISK"
  exit 1
fi

lsblk "$DISK"
echo ""
read -rp "This ERASES everything on $DISK. Continue? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."; exit 1
fi

# Partition names: /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/sda -> /dev/sda1
if [[ "$DISK" =~ [0-9]$ ]]; then PART="${DISK}p"; else PART="$DISK"; fi
SWAP_END="$((512 + SWAP_GIB * 1024))MiB"

# Clear old signatures (LVM, RAID, filesystems) so nothing auto-activates
vgchange -an >/dev/null 2>&1 || true
while read -r OLD_PART; do
  wipefs -a "$OLD_PART"
done < <(lsblk -nrpo NAME "$DISK" | tail -n +2)
wipefs -a "$DISK"

echo "Partitioning $DISK ($( ((EFI)) && echo UEFI || echo BIOS ), swap: ${SWAP_GIB}GiB)..."
parted -s "$DISK" -- mklabel gpt
if ((EFI)); then
  parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
  parted -s "$DISK" -- set 1 esp on
  parted -s "$DISK" -- mkpart swap linux-swap 512MiB "$SWAP_END"
  BOOT="${PART}1"
else
  parted -s "$DISK" -- mkpart bios 1MiB 2MiB
  parted -s "$DISK" -- set 1 bios_grub on
  parted -s "$DISK" -- mkpart swap linux-swap 2MiB "$SWAP_END"
  BOOT=""
fi
parted -s "$DISK" -- mkpart root "$SWAP_END" 100%
SWAP_DEV="${PART}2"
ROOT="${PART}3"

partprobe "$DISK"
udevadm settle

echo "Formatting..."
if [[ -n "$BOOT" ]]; then mkfs.fat -F 32 "$BOOT"; fi
mkswap "$SWAP_DEV"
mkfs.ext4 -F "$ROOT"

echo "Mounting..."
# Explicit types: udev hasn't re-probed the fresh filesystems yet, so mount's
# autodetection falls back to /proc/filesystems, which lacks ext4 until the
# module is loaded (the ISO kernel builds it as a module).
mount -t ext4 "$ROOT" /mnt
MOUNTED=1
if [[ -n "$BOOT" ]]; then
  mkdir -p /mnt/boot
  mount -t vfat "$BOOT" /mnt/boot
fi
swapon "$SWAP_DEV"

# The by-uuid links must exist before nixos-generate-config, or it falls back
# to /dev/sdX paths and the UUID patching below finds nothing.
udevadm settle

echo "Generating hardware config..."
nixos-generate-config --root /mnt

uuid_after() { # uuid_after <grep -A n> <pattern> <file>
  grep -A"$1" "$2" "$3" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' | head -n1 || true
}

# ── Existing host: point its hardware config at this disk ────────────────

if [[ -z "$HOST_TYPE" ]]; then
  if [[ -f "$HOST_DIR/_hardware-configuration.nix" ]]; then
    # Created by this script: take the freshly generated file as is.
    cp "$HW_CONF" "$HOST_DIR/_hardware-configuration.nix"
    git -C "$DOTFILES_DIR" add "$HOST_DIR/_hardware-configuration.nix"
  else
    # Hand-maintained hardware.nix: only swap the filesystem UUIDs.
    echo "Updating $INSTALL_HOST hardware.nix with UUIDs from this disk..."
    HW_NIX="$HOST_DIR/hardware.nix"

    NAMES=(root swap)
    NEW=("$(uuid_after 2 '"/"' "$HW_CONF")" "$(uuid_after 3 'swapDevices' "$HW_CONF")")
    OLD=("$(uuid_after 2 'fileSystems\."/"' "$HW_NIX")" "$(uuid_after 3 'swapDevices' "$HW_NIX")")
    if ((EFI)); then
      NAMES+=(boot)
      NEW+=("$(uuid_after 2 '"/boot"' "$HW_CONF")")
      OLD+=("$(uuid_after 2 'fileSystems\."/boot"' "$HW_NIX")")
    fi

    for i in "${!NAMES[@]}"; do
      if [[ -z "${OLD[$i]}" || -z "${NEW[$i]}" ]]; then
        echo "Could not find the ${NAMES[$i]} UUID (old: '${OLD[$i]}', new: '${NEW[$i]}')."
        echo "Edit $HW_NIX by hand (see $HW_CONF), then run nixos-install yourself."
        exit 1
      fi
      sed -i "s|${OLD[$i]}|${NEW[$i]}|g" "$HW_NIX"
    done

    git -C "$DOTFILES_DIR" add "$HW_NIX"
  fi
fi

# ── New host: scaffold from the type profile ─────────────────────────────

if [[ -n "$HOST_TYPE" ]]; then
  mkdir -p "$HOST_DIR"
  # The leading underscore keeps import-tree from loading it as a
  # flake-parts module; the host file imports it as a NixOS module.
  cp "$HW_CONF" "$HOST_DIR/_hardware-configuration.nix"

  # Kernel names like /dev/sda can change between boots; prefer a stable
  # by-id link (virtio disks without a serial have none).
  GRUB_DEVICE=$DISK
  for LINK in /dev/disk/by-id/*; do
    if [[ "$LINK" != *-part* && "$(readlink -f "$LINK")" == "$DISK" ]]; then
      GRUB_DEVICE=$LINK
      break
    fi
  done

  BOOT_LINES=""
  if ((!EFI)); then
    BOOT_LINES="
      commonConfig.bootEFI = false;
      boot.loader.grub.enable = true;
      boot.loader.grub.device = \"$GRUB_DEVICE\";"
  fi

  # The release this host is installed with, from the flake's nixpkgs
  STATE_VERSION=$(nix eval --raw --impure --expr \
    "(builtins.getFlake \"git+file://$DOTFILES_DIR\").inputs.nixpkgs.lib.trivial.release")

  cat > "$HOST_DIR/$INSTALL_HOST.nix" <<NIXEOF
{ inputs, ... }:
{
  den.aspects."$INSTALL_HOST".nixos =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.${HOST_TYPE}Profile
        ./_hardware-configuration.nix
      ];

      systemConstants.system.host = "$INSTALL_HOST";
      system.stateVersion = "$STATE_VERSION";$BOOT_LINES
    };
}
NIXEOF

  sed -i "s|^  $TOPOLOGY_ANCHOR|  den.hosts.x86_64-linux.$INSTALL_HOST = { };\n&|" "$TOPOLOGY"
  if ! grep -q "den\.hosts\.x86_64-linux\.$INSTALL_HOST = " "$TOPOLOGY"; then
    echo "Could not register $INSTALL_HOST in $TOPOLOGY (anchor line missing)."
    exit 1
  fi

  git -C "$DOTFILES_DIR" add "$HOST_DIR" "$TOPOLOGY"
fi

# ── Install ──────────────────────────────────────────────────────────────

echo ""
echo "Installing NixOS for host: $INSTALL_HOST"
# No root password: erik is in wheel and root ssh login is off
nixos-install --no-root-passwd --flake "$DOTFILES_DIR#$INSTALL_HOST"

# /tmp is gone after reboot; keep the clone (with its new/patched host files)
# before anything interactive can fail.
install -d -m 700 /mnt/home/erik
cp -a "$DOTFILES_DIR" /mnt/home/erik/dotfiles
nixos-enter --root /mnt -c 'chown -R erik:users /home/erik'

# commonConfig sets no password for erik and ssh is key-only.
echo "Set a password for erik:"
until nixos-enter --root /mnt -c 'passwd erik'; do
  echo "Try again."
done

echo ""
echo "Done. Dotfiles are in /home/erik/dotfiles. After first boot:"
echo "  - commit the host changes ($INSTALL_HOST) and push"
if [[ -n "$HOST_TYPE" ]]; then
  echo "  - add $INSTALL_HOST to nix/secrets/hosts.nix"
  echo "  - if it needs sops secrets, add its age key to nix/secrets/.sops.yaml"
fi
echo "Reboot when ready."
