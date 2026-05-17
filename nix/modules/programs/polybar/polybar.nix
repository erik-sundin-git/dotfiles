{ ... }:
{
  flake.modules.homeManager.polybar =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;
      c = config.theme;
      rightModules = lib.concatStringsSep " " (
        [
          "vpn"
          "ipv6"
        ]
        ++ lib.optionals laptop [ "wireless" ]
        ++ [ "ethernet" ]
        ++ lib.optionals laptop [ "battery" ]
        ++ [ "disk" ]
        ++ lib.optionals (thermalPath != null) [ "temperature" ]
        ++ [
          "memory"
          "date"
        ]
      );
    in
    {
      _module.args.mkScript =
        { exec, interval ? 5, clickLeft ? null }:
        { type = "custom/script"; inherit exec interval; }
        // lib.optionalAttrs (clickLeft != null) { click-left = clickLeft; };

      services.polybar = {
        enable = true;

        package = pkgs.polybarFull;

        script = "polybar main &";

        settings = {
          "bar/main" = {
            bottom = true;
            width = "100%";
            height = 22;
            background = c.background;
            foreground = c.foreground;
            font-0 = "JetBrainsMono Nerd Font:size=12;3";
            modules-left = "i3 tray";
            modules-right = rightModules;
            radius = 0;
            padding-right = 1;
            module-margin = 1;
            separator = "|";
            separator-foreground = c.brightBlack;
          };

          "module/tray" = {
            type = "internal/tray";
          };

          "module/i3" = {
            type = "internal/i3";
            label-focused = "%index%";
            label-focused-background = c.blue;
            label-focused-foreground = c.black;
            label-focused-padding = 1;
            label-unfocused = "%index%";
            label-unfocused-foreground = c.brightBlack;
            label-unfocused-padding = 1;
            label-urgent = "%index%";
            label-urgent-foreground = c.red;
            label-urgent-padding = 1;
            label-visible = "%index%";
            label-visible-padding = 1;
            label-mode = " %mode% ";
            label-mode-foreground = c.black;
            label-mode-background = c.yellow;
          };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            date = "%Y-%m-%d";
            time = "%H:%M:%S";
            label = "%date% %time%";
          };
        };
      };
    };
}
