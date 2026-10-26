{ den, inputs, ... }:
{
  den.aspects.specter = {
    nixos =
      { ... }:
      {
        imports = with inputs.self.modules.nixos; [ laptopProfile ];

        systemConstants.system.host = "specter";

        home-manager.users.erik = {
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone8/temp";
        };

        boot.kernelParams = [
          "usbcore.autosuspend=-1"
          "acpi_osi=Linux"
        ];
      };
  };
}
