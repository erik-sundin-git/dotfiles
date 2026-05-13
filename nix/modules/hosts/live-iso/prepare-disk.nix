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
            git
          ];
          text = ''
                        DISK=''${1:?Usage: prepare-disk /dev/nvme0n1 [swap-size]}
                        SWAP=''${2:-16G}
                        DOTFILES_DIR=/tmp/dotfiles
                        DOTFILES_REPO=https://github.com/erik-sundin-git/dotfiles.git
                        HW_CONF=/mnt/etc/nixos/hardware-configuration.nix

                        # ── Disk setup ──────────────────────────────────────────────────

                        echo "Partitioning $DISK (swap: $SWAP)..."
                        parted "$DISK" -- mklabel gpt
                        parted "$DISK" -- mkpart ESP fat32 1MB 512MB
                        parted "$DISK" -- set 1 esp on
                        parted "$DISK" -- mkpart swap linux-swap 512MB "$SWAP"
                        parted "$DISK" -- mkpart root ext4 "$SWAP" 100%

                        partprobe "$DISK"
                        sleep 1

                        if [[ "$DISK" == *nvme* ]]; then
                          BOOT="''${DISK}p1"
                          SWAP_DEV="''${DISK}p2"
                          ROOT="''${DISK}p3"
                        else
                          BOOT="''${DISK}1"
                          SWAP_DEV="''${DISK}2"
                          ROOT="''${DISK}3"
                        fi

                        echo "Formatting..."
                        mkfs.fat -F 32 "$BOOT"
                        mkswap "$SWAP_DEV"
                        mkfs.ext4 -F "$ROOT"

                        echo "Mounting..."
                        mount "$ROOT" /mnt
                        mkdir -p /mnt/boot
                        mount "$BOOT" /mnt/boot
                        swapon "$SWAP_DEV"

                        echo "Generating hardware config..."
                        nixos-generate-config --root /mnt

                        echo "Cloning dotfiles..."
                        git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"

                        # ── Host selection ───────────────────────────────────────────────

                        echo ""
                        echo "Select host to install:"
                        echo "  1) nomad   (Hyprland laptop)"
                        echo "  2) ether   (XFCE VM — GRUB bootloader, not EFI)"
                        echo "  3) specter (i3 laptop)"
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

                        # ── Existing host: update hardware UUIDs ─────────────────────────

                        if [[ "$INSTALL_HOST" != new ]]; then
                          echo "Updating $INSTALL_HOST hardware.nix with UUIDs from this disk..."
                          HW_NIX="$DOTFILES_DIR/nix/modules/hosts/$INSTALL_HOST/hardware.nix"

                          NEW_ROOT_UUID=$(grep -A2 '"/"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          NEW_BOOT_UUID=$(grep -A2 '"/boot"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          NEW_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')

                          OLD_ROOT_UUID=$(grep -A2 'fileSystems\."/"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          OLD_BOOT_UUID=$(grep -A2 'fileSystems\."/boot"' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          OLD_SWAP_UUID=$(grep -A3 'swapDevices' "$HW_NIX" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')

                          sed -i "s|$OLD_ROOT_UUID|$NEW_ROOT_UUID|g" "$HW_NIX"
                          sed -i "s|$OLD_BOOT_UUID|$NEW_BOOT_UUID|g" "$HW_NIX"
                          sed -i "s|$OLD_SWAP_UUID|$NEW_SWAP_UUID|g" "$HW_NIX"

                          git -C "$DOTFILES_DIR" add "nix/modules/hosts/$INSTALL_HOST/hardware.nix"
                        fi

                        # ── New host ─────────────────────────────────────────────────────

                        if [[ "$INSTALL_HOST" == new ]]; then
                          read -rp "Hostname: " INSTALL_HOST

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
                          echo "  1) nomad   (Hyprland laptop)"
                          echo "  2) specter (i3 laptop)"
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
                          ROOT_UUID=$(grep -A2 '"/"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          BOOT_UUID=$(grep -A2 '"/boot"' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')
                          SWAP_UUID=$(grep -A3 'swapDevices' "$HW_CONF" | grep 'by-uuid' | sed 's|.*/by-uuid/||;s|".*||')

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
          '';
        })
      ];
    };
}
