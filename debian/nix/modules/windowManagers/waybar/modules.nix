{ ... }:

{
  flake.modules.homeManager.waybar-modules =
    { config, ... }:
    let
      waybarDir = "${config.systemConstants.configDir}/modules/windowManagers/waybar";
    in
    {
      programs.waybar.settings.mainBar = {
        "hyprland/workspaces" = {
          format = "{name}";
          disable-scroll = true;
        };

        "hyprland/window" = {
          format = "{initialTitle}";
          rewrite = {
            "(.*) - Mozilla Firefox" = "🌎 $1";
            "(.*) - zsh" = "> [$1]";
          };
        };

        "hyprland/submap" = {
          format = "{}";
          max-length = 8;
          tooltip = false;
        };

        clock = {
          format = "{:%a %d %b %H:%M}";
          tooltip = false;
        };

        battery = {
          format = "{capacity}% {icon}";
          format-alt = "{time} {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          format-charging = "{capacity}% ";
          interval = 30;
          states = {
            warning = 25;
            critical = 10;
          };
          tooltip = false;
        };

        network = {
          format = "{icon}";
          format-alt = "{ipaddr}/{cidr} {icon}";
          format-alt-click = "click-right";
          format-icons = {
            wifi = [
              "󰤯"
              "󰤟"
              "󰤨"
            ];
            ethernet = [ "" ];
            disconnected = [ "" ];
          };
          on-click = "alacritty -e nmtui";
          tooltip = false;
        };

        pulseaudio = {
          format = "{icon}";
          format-alt = "{volume} {icon}";
          format-alt-click = "click-right";
          format-muted = "";
          format-icons = {
            phone = [
              ""
              ""
              ""
              ""
            ];
            default = [
              ""
              ""
              ""
            ];
          };
          scroll-step = 10;
          on-click = "pavucontrol";
          tooltip = false;
        };

        "custom/airpods" = {
          format = "  ";
          format-alt = "{}";
          return-type = "json";
          interval = 30;
          exec = "${waybarDir}/modules/airpods.sh 'L:' 'R:'";
          tooltip = false;
        };

        "custom/storage" = {
          format = "{}";
          format-alt = "{percentage}% ";
          format-alt-click = "click-right";
          return-type = "json";
          interval = 60;
          exec = "~/.config/waybar/modules/storage.sh";
        };

        "custom/spotify" = {
          exec = "/usr/bin/python3 /home/erik/.config/waybar/mediaplayer.py --player ncspot";
          format = "{}  ";
          return-type = "json";
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        tray = {
          icon-size = 18;
        };
      };
    };
}
