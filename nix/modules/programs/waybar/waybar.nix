{ ... }:
{
  flake.modules.homeManager.waybar =
    {
      config,
      lib,
      pkgs,
      hexToRgba,
      ...
    }:
    let
      c = config.theme;
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;

      tempScript = pkgs.writeShellScript "waybar-temp" ''
        awk '{printf "%.0f °C", $1/1000}' ${thermalPath}
      '';

      vpnScript = pkgs.writeShellScript "waybar-vpn" ''
        result=$(vpn-status 2>/dev/null)
        if [ -n "$result" ]; then
          echo "{\"text\": \"$result\", \"class\": \"connected\"}"
        else
          echo "{\"text\": \"VPN\", \"class\": \"disconnected\"}"
        fi
      '';

    in
    {
      programs.waybar = {
        enable = true;

        settings = [
          (
            {
              position = "bottom";
              height = 18;
              spacing = 4;

              modules-left = [
                "hyprland/workspaces"
                "hyprland/submap"
                "tray"
              ];
              modules-right = [
                "custom/vpn"
                "network"
              ]
              ++ lib.optionals laptop [ "battery" ]
              ++ [
                "disk"
                "memory"
                "clock"
              ]
              ++ lib.optionals (thermalPath != null) [ "custom/temperature" ];

              tray = {
                icon-size = 14;
                spacing = 4;
              };

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
                bat = "BAT0";
                adapter = "AC";
                format = "{icon} {capacity}%";
                format-charging = "󱐋 {capacity}%";
                format-full = "{icon} full";
                format-icons = [
                  "󰂎"
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                  "󰁹"
                ];
                full-at = 98;
                states.low = 30;
                interval = 30;
              };

              disk = {
                format = " {free}";
                interval = 60;
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
            // {
              "custom/vpn" = {
                exec = "${vpnScript}";
                return-type = "json";
                interval = 5;
                format = "{}";
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
            font-size: 11px;
            min-height: 0;
          }

          window#waybar {
            background: ${hexToRgba c.background "0.9"};
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
            padding: 0 6px;
          }

          #clock {
            color: ${c.cyan};
            padding: 0 6px;
          }

          #battery {
            color: ${c.green};
            padding: 0 6px;
          }

          #battery.charging {
            color: ${c.yellow};
          }

          #battery.low {
            color: ${c.red};
          }

          #disk {
            color: ${c.blue};
            padding: 0 6px;
          }

          #memory {
            color: ${c.magenta};
            padding: 0 6px;
          }

          #network {
            color: ${c.blue};
            padding: 0 6px;
          }

          #network.disconnected {
            color: ${c.brightBlack};
          }

          #custom-temperature {
            color: ${c.yellow};
            padding: 0 6px;
          }

          #custom-vpn {
            color: ${c.red};
            padding: 0 6px;
          }

          #custom-vpn.connected {
            color: ${c.green};
          }

        '';
      };
    };
}
