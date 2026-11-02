{ ... }:
{
  flake.modules.homeManager.polybar =
    {
      pkgs,
      config,
      lib,
      isLaptop,
      ...
    }:
    let
      thermalPath = config.systemConstants.thermalZonePath;
      c = config.theme;
      rightModules = lib.concatStringsSep " " (
        [
          "vpn"
          "ipv6"
        ]
        ++ lib.optionals isLaptop [ "wireless" ]
        ++ [ "ethernet" ]
        ++ lib.optionals isLaptop [ "battery" ]
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
        {
          exec,
          interval ? 5,
          clickLeft ? null,
        }:
        {
          type = "custom/script";
          inherit exec interval;
        }
        // lib.optionalAttrs (clickLeft != null) { click-left = clickLeft; };

      # HM's unit PATH is only polybar + wrappers, so module scripts calling
      # vpn-status, awk, rm or touch by name would fail. Add the user and
      # system profiles.
      systemd.user.services.polybar.Service.Environment = lib.mkForce [
        "PATH=${config.services.polybar.package}/bin:/run/wrappers/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
      ];

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
            font-0 = "${c.fontFamily}:size=12;3";
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
            label-focused-background = c.accent;
            label-focused-foreground = c.background;
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
            label-mode-foreground = c.background;
            label-mode-background = c.yellow;
          };

          "module/date" = {
            type = "internal/date";
            interval = 5;
            date = "%Y-%m-%d";
            time = "%H:%M";
            label = "%date% %time%";
          };
        };
      };
    };
}
