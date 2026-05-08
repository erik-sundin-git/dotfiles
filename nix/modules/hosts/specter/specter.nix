{ den, inputs, ... }:
{
  den.aspects.specter = {
    nixos =
      { config, pkgs, ... }:
      let
        sysConst = {
          type = "laptop";
          host = "specter";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          i3Stack
          commonDesktop
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.commonHome ];
          systemConstants.system = sysConst;
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
