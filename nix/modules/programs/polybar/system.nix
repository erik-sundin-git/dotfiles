{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.polybar =
    {
      config,
      lib,
      ...
    }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;
      c = config.colors;
    in
    {
      services.polybar.settings = {
        "module/disk" = {
          type = "internal/fs";
          mount-0 = "/";
          interval = 30;
          label-mounted = "  %free%";
        };

        "module/memory" = {
          type = "internal/memory";
          interval = 5;
          warn-percentage = 90;
          label = " %used%";
          label-warn = " %used%";
          label-warn-foreground = c.yellow;
        };
      }
      // lib.optionalAttrs laptop {
        "module/battery" = {
          type = "internal/battery";
          battery = "BAT0";
          adapter = "AC";
          full-at = 98;
          low-at = 30;
          interval = 30;
          label-charging = " %percentage%%";
          label-discharging = "BAT %percentage%%";
          label-full = "BAT full";
          label-low = "BAT %percentage%%";
          label-low-foreground = c.red;
        };
      }
      // lib.optionalAttrs (thermalPath != null) {
        "module/temperature" = {
          type = "custom/script";
          exec = ''awk '{printf "%.0f °C", $1/1000}' ${thermalPath}'';
          interval = 5;
        };
      };
    };
}
