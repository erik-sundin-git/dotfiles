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
          commonDesktop
          i3Stack
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            commonHome
            i3Stack
          ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone8/temp";
          systemConstants.latitude = 59.33; # Stockholm
          systemConstants.longitude = 18.07; # Stockholm
        };

        services.xserver.displayManager.lightdm.enable = false;
        services.xserver.displayManager.startx.enable = true;

        boot.kernelParams = [
          "usbcore.autosuspend=-1"
          "acpi_osi=Linux"
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
