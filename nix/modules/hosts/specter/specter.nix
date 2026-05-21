{ den, inputs, ... }:
{
  den.aspects.specter = {
    nixos =
      { ... }:
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
          swayfxStack
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            commonHome
            swayfxStack
          ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone8/temp";
        };

        boot.kernelParams = [
          "usbcore.autosuspend=-1"
          "acpi_osi=Linux"
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
