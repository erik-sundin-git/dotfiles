{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { pkgs, ... }:
      let
        sysConst = {
          type = "laptop";
          host = "nomad";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonDesktop
          i3Stack
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            commonHome
            i3Stack
            alacritty
            vpn
          ];
          systemConstants.system = sysConst;
          systemConstants.latitude = 59.33;
          systemConstants.longitude = 18.07;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone6/temp";
          home.packages = with pkgs; [ protonmail-desktop ];
        };

        services.xserver.displayManager.lightdm.enable = false;
        services.xserver.displayManager.startx.enable = true;

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
