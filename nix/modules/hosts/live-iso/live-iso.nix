{ inputs, ... }:
{
  flake.nixosConfigurations.live-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
      inputs.home-manager.nixosModules.home-manager
      inputs.self.modules.nixos.liveIsoConfig
      inputs.self.modules.nixos.prepareDisk
    ];
  };

  perSystem =
    { ... }:
    {
      packages.iso = inputs.self.nixosConfigurations.live-iso.config.system.build.isoImage;
    };
}
