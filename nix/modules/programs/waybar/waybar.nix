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
      isHyprland = config.wayland.windowManager.hyprland.enable;
      isSway = config.wayland.windowManager.sway.enable;

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
              height = 24;
              spacing = 4;

              modules-left =
                (
                  if isHyprland then
                    [ "hyprland/workspaces" "hyprland/submap" ]
                  else if isSway then
                    [ "sway/workspaces" "sway/mode" ]
                  else
                    [ ]
                )
                ++ [ "tray" ];
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

              "hyprland/workspaces" = lib.mkIf isHyprland {
                format = "{id}";
                on-click = "activate";
              };

              "hyprland/submap" = lib.mkIf isHyprland {
                format = "{}";
                default-submap = "";
              };

              "sway/workspaces" = lib.mkIf isSway {
                format = "{name}";
              };

              "sway/mode" = lib.mkIf isSway {
                format = "{}";
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
            font-size: 13px;
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

          #submap, #mode {
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
