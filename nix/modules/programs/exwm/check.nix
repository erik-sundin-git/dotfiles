{ inputs, ... }:
{
  # No host imports exwmStack yet, so nothing else would evaluate it. This
  # eval-only system keeps it from rotting: `nix flake check --no-build` (and
  # CI) evaluates its toplevel, which includes the generated my-exwm-nix.el,
  # so a sway bind without an EXWM translation fails here.
  perSystem =
    { lib, system, ... }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        exwm-eval =
          (inputs.nixpkgs.lib.nixosSystem {
            modules = with inputs.self.modules.nixos; [
              desktopBaseProfile
              exwmStack
              {
                nixpkgs.hostPlatform = "x86_64-linux";
                systemConstants.system.host = "exwm-test";
                system.stateVersion = "25.11";
                fileSystems."/" = {
                  device = "/dev/disk/by-label/nixos";
                  fsType = "ext4";
                };
                commonConfig.bootEFI = false;
                boot.loader.grub.enable = true;
                boot.loader.grub.device = "nodev";
              }
            ];
          }).config.system.build.toplevel;
      };
    };
}
