{ ... }:
{
  flake.modules.homeManager.waybar =
    { config, lib, pkgs, ... }:
    let
      c = config.theme;
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;

      tempScript = pkgs.writeShellScript "waybar-temp" ''
        awk '{printf "%.0f °C", $1/1000}' ${thermalPath}
      '';
    in
    {
      programs.waybar = {
        enable = true;

        settings = [
          (
            {
              position = "bottom";
              height = 22;
              spacing = 4;

              modules-left = [
                "hyprland/workspaces"
                "hyprland/submap"
              ];
              modules-right =
                [ "network" ]
                ++ lib.optionals laptop [ "battery" ]
                ++ [ "memory" "clock" ]
                ++ lib.optionals (thermalPath != null) [ "custom/temperature" ];

              "hyprland/workspaces" = {
                format = "{id}";
                on-click = "activate";
              };

              "hyprland/submap" = {
                format = "{}";
                default-submap = "";
              };

              network = {
                format-wifi = "W: {essid}";
                format-ethernet = "E: {ipaddr}";
                format-disconnected = "down";
                interval = 5;
              };

              battery = {
                format = "BAT {capacity}%";
                format-charging = " {capacity}%";
                format-full = "BAT full";
                full-at = 98;
                states.low = 30;
                format-low = "BAT {capacity}%";
                interval = 30;
              };

              memory = {
                format = " {used:0.1f}G";
                interval = 5;
              };

              clock = {
                format = "{:%Y-%m-%d %H:%M:%S}";
                interval = 1;
              };
            }
            // lib.optionalAttrs (thermalPath != null) {
              "custom/temperature" = {
                exec = "${tempScript}";
                interval = 5;
                format = "{}";
              };
            }
          )
        ];

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "JetBrainsMono Nerd Font";
            font-size: 12px;
            min-height: 0;
          }

          window#waybar {
            background: alpha(${c.background}, 0.85);
            color: ${c.foreground};
          }

          #workspaces button {
            color: ${c.brightBlack};
            padding: 0 4px;
            background: transparent;
          }

          #workspaces button.active {
            background: ${c.blue};
            color: ${c.black};
          }

          #workspaces button.urgent {
            color: ${c.red};
          }

          #submap {
            color: ${c.yellow};
            padding: 0 4px;
          }

          #clock,
          #battery,
          #memory,
          #network,
          #temperature {
            padding: 0 4px;
          }

          #battery.low {
            color: ${c.red};
          }
        '';
      };
    };
}
