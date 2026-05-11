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

          environment.systemPackages = with pkgs; [ git ];

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
