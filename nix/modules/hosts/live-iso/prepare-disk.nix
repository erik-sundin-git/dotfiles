{ ... }:
{
  flake.modules.nixos.prepareDisk =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "prepare-disk";
          runtimeInputs = with pkgs; [
            parted
            util-linux
            e2fsprogs
            dosfstools
            btrfs-progs
            git
            git-crypt
            systemd
          ];
          text = ''
                        DISK=''${1:?Usage: prepare-disk /dev/nvme0n1 [swap-GiB]}
                        SWAP_GIB=''${2:-16}
                        DOTFILES_DIR=/tmp/dotfiles
                        DOTFILES_REPO=https://github.com/erik-sundin-git/dotfiles.git
                        HW_CONF=/mnt/etc/nixos/hardware-configuration.nix

                        # ── Host selection ───────────────────────────────────────────────
                        # Asked before disk setup so we can pick the right partition layout.

                        echo ""
                        echo "Select host to install:"
                        echo "  1) nomad   (SwayFX laptop)"
                        echo "  2) ether   (XFCE VM — GRUB bootloader, not EFI)"
                        echo "  3) specter (SwayFX laptop)"
                        echo "  4) New host"
                        echo ""
                        read -rp "Choice [1-4]: " HOST_CHOICE

                        case "$HOST_CHOICE" in
                          1) INSTALL_HOST=nomad ;;
                          2) INSTALL_HOST=ether ;;
                          3) INSTALL_HOST=specter ;;
                          4) INSTALL_HOST=new ;;
                          *) echo "Invalid choice: $HOST_CHOICE"; exit 1 ;;
                        esac

                        # ── Disk setup ──────────────────────────────────────────────────

                        if [[ ! -b "$DISK" ]]; then
                          echo "$DISK is not a block device"; exit 1
                        fi
                        lsblk "$DISK"
                        echo ""
                        read -rp "This ERASES everything on $DISK. Type the device path to confirm: " CONFIRM
                        if [[ "$CONFIRM" != "$DISK" ]]; then
                          echo "Aborted."; exit 1
                        fi

                        # Partition names: /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/sda -> /dev/sda1
                        if [[ "$DISK" =~ [0-9]$ ]]; then PART="''${DISK}p"; else PART="$DISK"; fi
                        SWAP_END="$((512 + SWAP_GIB * 1024))MiB"

                        echo "Partitioning $DISK (swap: ''${SWAP_GIB}GiB)..."
                        parted -s "$DISK" -- mklabel gpt
                        if [[ "$INSTALL_HOST" == ether ]]; then
                          # ether boots BIOS GRUB from a GPT disk, which needs a bios_grub partition.
                          parted -s "$DISK" -- mkpart bios 1MiB 2MiB
                          parted -s "$DISK" -- set 1 bios_grub on
                          parted -s "$DISK" -- mkpart swap linux-swap 2MiB "$SWAP_END"
                          parted -s "$DISK" -- mkpart root "$SWAP_END" 100%
                          BOOT=""
                          SWAP_DEV="''${PART}2"
                          ROOT="''${PART}3"
                        else
                          parted -s "$DISK" -- mkpart ESP fat32 1MiB 512MiB
                          parted -s "$DISK" -- set 1 esp on
                          parted -s "$DISK" -- mkpart swap linux-swap 512MiB "$SWAP_END"
                          parted -s "$DISK" -- mkpart root "$SWAP_END" 100%
                          BOOT="''${PART}1"
                          SWAP_DEV="''${PART}2"
                          ROOT="''${PART}3"
                        fi

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

                        echo "Cloning dotfiles..."
                        git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"

                        # nix/secrets/hosts.nix is git-crypt encrypted and evaluated by every host.
                        read -rp "Path to git-crypt key (e.g. a USB stick; empty to skip): " CRYPT_KEY
                        if [[ -n "$CRYPT_KEY" ]]; then
                          git -C "$DOTFILES_DIR" crypt unlock "$CRYPT_KEY"
                        else
                          echo "Warning: repo left locked; evaluation will fail on nix/secrets/hosts.nix."
                        fi


                        # ── Existing host: update hardware config ─────────────────────────

                        if [[ "$INSTALL_HOST" != new ]]; then
                          echo "Updating $INSTALL_HOST hardware.nix with UUIDs from this disk..."
                          HW_NIX="$DOTFILES_DIR/nix/modules/hosts/$INSTALL_HOST/hardware.nix"

                          NEW_BOOT_UUID=$(grep -A2 '"/boot"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          NEW_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          NEW_ROOT_UUID=$(grep -A2 '"/"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)

                          OLD_ROOT_UUID=$(grep -A2 'fileSystems\."/"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          OLD_BOOT_UUID=$(grep -A2 'fileSystems\."/boot"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          OLD_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)

                          [[ -n "$OLD_ROOT_UUID" && -n "$NEW_ROOT_UUID" ]] && sed -i "s|$OLD_ROOT_UUID|$NEW_ROOT_UUID|g" "$HW_NIX"
                          [[ -n "$OLD_BOOT_UUID" && -n "$NEW_BOOT_UUID" ]] && sed -i "s|$OLD_BOOT_UUID|$NEW_BOOT_UUID|g" "$HW_NIX"
                          [[ -n "$OLD_SWAP_UUID" && -n "$NEW_SWAP_UUID" ]] && sed -i "s|$OLD_SWAP_UUID|$NEW_SWAP_UUID|g" "$HW_NIX"

                          git -C "$DOTFILES_DIR" add "nix/modules/hosts/$INSTALL_HOST/hardware.nix"
                        fi

                        # ── New host ─────────────────────────────────────────────────────

                        if [[ "$INSTALL_HOST" == new ]]; then
                          read -rp "Hostname: " INSTALL_HOST
                          if [[ ! "$INSTALL_HOST" =~ ^[a-z][a-z0-9-]*$ || -e "$DOTFILES_DIR/nix/modules/hosts/$INSTALL_HOST" ]]; then
                            echo "Invalid or existing hostname: $INSTALL_HOST"; exit 1
                          fi

                          echo ""
                          echo "System type:"
                          echo "  1) laptop"
                          echo "  2) desktop"
                          read -rp "Choice [1-2]: " TYPE_CHOICE
                          case "$TYPE_CHOICE" in
                            1) SYS_TYPE=laptop ;;
                            2) SYS_TYPE=desktop ;;
                            *) echo "Invalid choice: $TYPE_CHOICE"; exit 1 ;;
                          esac

                          echo ""
                          echo "Template for main config:"
                          echo "  1) nomad   (SwayFX laptop)"
                          echo "  2) specter (SwayFX laptop)"
                          echo "  3) None    (minimal scaffold)"
                          read -rp "Choice [1-3]: " TMPL_CHOICE
                          case "$TMPL_CHOICE" in
                            1) TEMPLATE=nomad ;;
                            2) TEMPLATE=specter ;;
                            3) TEMPLATE="" ;;
                            *) echo "Invalid choice: $TMPL_CHOICE"; exit 1 ;;
                          esac

                          HOST_DIR="$DOTFILES_DIR/nix/modules/hosts/$INSTALL_HOST"
                          mkdir -p "$HOST_DIR"

                          # Generate hardware.nix in den.aspects format
                          ROOT_UUID=$(grep -A2 '"/"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          BOOT_UUID=$(grep -A2 '"/boot"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          SWAP_UUID=$(grep -A3 'swapDevices' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||' || true)
                          if [[ -z "$ROOT_UUID" || -z "$BOOT_UUID" || -z "$SWAP_UUID" ]]; then
                            echo "Could not read filesystem UUIDs from $HW_CONF"; exit 1
                          fi

                          AVAIL_MODULES=$(grep 'boot.initrd.availableKernelModules' "$HW_CONF" \
                            | sed 's/.*= \[/[/;s/\].*/]/' | sed 's/\s\+/ /g' | xargs)
                          KERNEL_MODULES=$(grep 'boot.kernelModules' "$HW_CONF" | grep -v 'initrd\|extra' \
                            | sed 's/.*= \[/[/;s/\].*/]/' | sed 's/\s\+/ /g' | xargs)

                          CPU_LINE=""
                          if grep -q 'cpu.intel' "$HW_CONF"; then
                            CPU_LINE="        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;"
                          elif grep -q 'cpu.amd' "$HW_CONF"; then
                            CPU_LINE="        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;"
                          fi

                          cat > "$HOST_DIR/hardware.nix" <<NIXEOF
{ den, lib, ... }:
{
  den.aspects."$INSTALL_HOST" = {
    nixos =
      {
        config,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        boot.initrd.availableKernelModules = $AVAIL_MODULES;
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = $KERNEL_MODULES;
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/$ROOT_UUID";
          fsType = "ext4";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/$BOOT_UUID";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        swapDevices = [
          { device = "/dev/disk/by-uuid/$SWAP_UUID"; }
        ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
$CPU_LINE
      };
  };
}
NIXEOF

                          # Generate or copy main config
                          if [[ -n "$TEMPLATE" ]]; then
                            TMPL_FILE="$DOTFILES_DIR/nix/modules/hosts/$TEMPLATE/$TEMPLATE.nix"
                            sed "s/$TEMPLATE/$INSTALL_HOST/g" "$TMPL_FILE" > "$HOST_DIR/$INSTALL_HOST.nix"
                            echo "Note: copied $TEMPLATE config — review thermal zone, lat/lon, and packages after install."
                          else
                            cat > "$HOST_DIR/$INSTALL_HOST.nix" <<NIXEOF
{ den, inputs, ... }:
{
  den.aspects."$INSTALL_HOST" = {
    nixos =
      { pkgs, ... }:
      let
        sysConst = {
          type = "$SYS_TYPE";
          host = "$INSTALL_HOST";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonDesktop
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [ commonHome ];
          systemConstants.system = sysConst;
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
NIXEOF
                          fi

                          # Register in topology.nix
                          TOPOLOGY="$DOTFILES_DIR/nix/modules/hosts/topology.nix"
                          sed -i "s/  den\.default/  den.hosts.x86_64-linux.$INSTALL_HOST = { };\n  den.default/" "$TOPOLOGY"

                          git -C "$DOTFILES_DIR" add \
                            "nix/modules/hosts/$INSTALL_HOST/" \
                            "nix/modules/hosts/topology.nix"
                        fi

                        # ── Install ──────────────────────────────────────────────────────

                        echo ""
                        echo "Installing NixOS for host: $INSTALL_HOST"
                        nixos-install --flake "$DOTFILES_DIR#$INSTALL_HOST"

                        # /tmp is gone after reboot; keep the clone (with any patched hardware.nix).
                        mkdir -p /mnt/home/erik
                        cp -a "$DOTFILES_DIR" /mnt/home/erik/dotfiles
                        chown -R 1000:100 /mnt/home/erik
                        echo "Dotfiles copied to /home/erik/dotfiles — commit the hardware.nix changes after first boot."
          '';
        })
      ];
    };
}
