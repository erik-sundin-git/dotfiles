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
HW_CONF=/mnt/etc/nixos/hardware-configuration.nix
TYPES=(laptop desktop server vm)

# ── Dotfiles ─────────────────────────────────────────────────────────────
# Cloned first: the host menu is read from topology.nix.

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  echo "Cloning dotfiles..."
  git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR" || {
    echo "Clone failed. No network? Connect with nmtui and try again."
    exit 1
  }
fi

# nix/secrets/hosts.nix is git-crypt encrypted and evaluated by every host.
if [[ "$(head -c 9 "$DOTFILES_DIR/nix/secrets/hosts.nix" | tr -d '\0')" == GITCRYPT ]]; then
  read -rp "Path to git-crypt key (e.g. a USB stick; empty to skip): " CRYPT_KEY
  if [[ -n "$CRYPT_KEY" ]]; then
    git -C "$DOTFILES_DIR" crypt unlock "$CRYPT_KEY"
  else
    echo "Warning: repo left locked; evaluation will fail on nix/secrets/hosts.nix."
  fi
fi

# ── Host selection ───────────────────────────────────────────────────────

mapfile -t HOSTS < <(grep -oP 'den\.hosts\.x86_64-linux\.\K[a-z0-9-]+' "$HOSTS_DIR/topology.nix")

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

if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || ((CHOICE < 1 || CHOICE > ${#HOSTS[@]} + ${#TYPES[@]})); then
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

# ── Disk setup ───────────────────────────────────────────────────────────

if [[ -z "$DISK" ]]; then
  echo ""
  lsblk -d -e 7,11 -o NAME,SIZE,MODEL
  read -rp "Disk to install to (e.g. /dev/nvme0n1): " DISK
fi
if [[ ! -b "$DISK" ]]; then
  echo "$DISK is not a block device"; exit 1
fi
lsblk "$DISK"
echo ""
read -rp "This ERASES everything on $DISK. Type the device path to confirm: " CONFIRM
if [[ "$CONFIRM" != "$DISK" ]]; then
  echo "Aborted."; exit 1
fi

# The layout follows how the ISO was booted: UEFI gets an ESP for
# systemd-boot, legacy BIOS gets a bios_grub partition for GRUB on GPT.
if [[ -d /sys/firmware/efi ]]; then EFI=1; else EFI=0; fi

# Partition names: /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/sda -> /dev/sda1
if [[ "$DISK" =~ [0-9]$ ]]; then PART="${DISK}p"; else PART="$DISK"; fi
SWAP_END="$((512 + SWAP_GIB * 1024))MiB"

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
mount "$ROOT" /mnt
if [[ -n "$BOOT" ]]; then
  mkdir -p /mnt/boot
  mount "$BOOT" /mnt/boot
fi
swapon "$SWAP_DEV"

echo "Generating hardware config..."
nixos-generate-config --root /mnt

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

    NEW_BOOT_UUID=$(grep -A2 '"/boot"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
    NEW_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
    NEW_ROOT_UUID=$(grep -A2 '"/"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)

    OLD_ROOT_UUID=$(grep -A2 'fileSystems\."/"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
    OLD_BOOT_UUID=$(grep -A2 'fileSystems\."/boot"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
    OLD_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)

    if [[ -n "$OLD_ROOT_UUID" && -n "$NEW_ROOT_UUID" ]]; then sed -i "s|$OLD_ROOT_UUID|$NEW_ROOT_UUID|g" "$HW_NIX"; fi
    if [[ -n "$OLD_BOOT_UUID" && -n "$NEW_BOOT_UUID" ]]; then sed -i "s|$OLD_BOOT_UUID|$NEW_BOOT_UUID|g" "$HW_NIX"; fi
    if [[ -n "$OLD_SWAP_UUID" && -n "$NEW_SWAP_UUID" ]]; then sed -i "s|$OLD_SWAP_UUID|$NEW_SWAP_UUID|g" "$HW_NIX"; fi

    git -C "$DOTFILES_DIR" add "$HW_NIX"
  fi
fi

# ── New host: scaffold from the type profile ─────────────────────────────

if [[ -n "$HOST_TYPE" ]]; then
  mkdir -p "$HOST_DIR"
  # The leading underscore keeps import-tree from loading it as a
  # flake-parts module; the host file imports it as a NixOS module.
  cp "$HW_CONF" "$HOST_DIR/_hardware-configuration.nix"

  BOOT_LINES=""
  if ((!EFI)); then
    BOOT_LINES="
      commonConfig.bootEFI = false;
      boot.loader.grub.enable = true;
      boot.loader.grub.device = \"$DISK\";"
  fi

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

      systemConstants.system.host = "$INSTALL_HOST";$BOOT_LINES
    };
}
NIXEOF

  TOPOLOGY="$HOSTS_DIR/topology.nix"
  sed -i "s/  den\.default/  den.hosts.x86_64-linux.$INSTALL_HOST = { };\n  den.default/" "$TOPOLOGY"

  git -C "$DOTFILES_DIR" add "$HOST_DIR" "$TOPOLOGY"
fi

# ── Install ──────────────────────────────────────────────────────────────

echo ""
echo "Installing NixOS for host: $INSTALL_HOST"
nixos-install --flake "$DOTFILES_DIR#$INSTALL_HOST"

# commonConfig sets no password for erik and ssh is key-only.
echo "Set a password for erik:"
nixos-enter --root /mnt -c 'passwd erik'

# /tmp is gone after reboot; keep the clone (with its new/patched host files).
mkdir -p /mnt/home/erik
cp -a "$DOTFILES_DIR" /mnt/home/erik/dotfiles
nixos-enter --root /mnt -c 'chown -R erik:users /home/erik'

echo ""
echo "Done. Dotfiles are in /home/erik/dotfiles. After first boot:"
echo "  - commit the host changes ($INSTALL_HOST) and push"
if [[ -n "$HOST_TYPE" ]]; then
  echo "  - add $INSTALL_HOST to nix/secrets/hosts.nix"
  echo "  - if it needs sops secrets, add its age key to nix/secrets/.sops.yaml"
fi
echo "Reboot when ready."
