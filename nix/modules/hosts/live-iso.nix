{ inputs, ... }:
{
  flake.nixosConfigurations.live-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
      inputs.home-manager.nixosModules.home-manager
      (
        { pkgs, ... }:
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ];

          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          isoImage.squashfsCompression = "lz4";

          environment.systemPackages = with pkgs; [
            git
            (writeShellApplication {
              name = "prepare-disk";
              runtimeInputs = [ parted util-linux e2fsprogs dosfstools ];
              text = ''
                DISK=''${1:?Usage: prepare-disk /dev/nvme0n1 [swap-size]}
                SWAP=''${2:-16G}

                echo "Partitioning $DISK (swap: $SWAP)..."
                parted "$DISK" -- mklabel gpt
                parted "$DISK" -- mkpart ESP fat32 1MB 512MB
                parted "$DISK" -- set 1 esp on
                parted "$DISK" -- mkpart swap linux-swap 512MB "$SWAP"
                parted "$DISK" -- mkpart root ext4 "$SWAP" 100%

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

                echo ""
                echo "=== hardware-configuration.nix ==="
                cat /mnt/etc/nixos/hardware-configuration.nix
                echo ""
                echo "Copy the UUIDs above into hosts/nomad/hardware.nix, push, then run:"
                echo "  sudo nixos-install --flake github:erik-sundin-git/dotfiles#nomad"
              '';
            })
          ];

          environment.etc."dotfiles".source = inputs.self;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.nixos = {
            imports = [ inputs.self.modules.homeManager.emacs ];
            home.username = "nixos";
            home.homeDirectory = "/home/nixos";
            home.stateVersion = "25.11";
          };
        }
      )
    ];
  };

  perSystem =
    { ... }:
    {
      packages.iso = inputs.self.nixosConfigurations.live-iso.config.system.build.isoImage;
    };
}
