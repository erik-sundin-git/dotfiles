{ den, inputs, ... }:
{
  den.aspects.ether = {
    nixos =
      { config, pkgs, ... }:
      let
        sysConst = {
          type = "desktop";
          host = "ether";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          xfceStack
          commonDesktop
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          systemConstants.system = sysConst;
        };

        commonDesktop.bootEFI = false;
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
        boot.loader.grub.useOSProber = true;
      };
  };
}
