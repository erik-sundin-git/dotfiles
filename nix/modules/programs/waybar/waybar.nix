{ ... }:
{
  flake.modules.homeManager.waybar =
    { config, lib, pkgs, ... }:
    let
      c = config.theme;
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;

      fromHex = s:
        let
          d = { "0"=0;"1"=1;"2"=2;"3"=3;"4"=4;"5"=5;"6"=6;"7"=7;
                "8"=8;"9"=9;"a"=10;"b"=11;"c"=12;"d"=13;"e"=14;"f"=15; };
          hi = d.${lib.toLower (lib.substring 0 1 s)};
          lo = d.${lib.toLower (lib.substring 1 1 s)};
        in hi * 16 + lo;
      hexToRgba = hex: alpha:
        let h = lib.removePrefix "#" hex;
        in "rgba(${toString (fromHex (lib.substring 0 2 h))}, ${toString (fromHex (lib.substring 2 2 h))}, ${toString (fromHex (lib.substring 4 2 h))}, ${alpha})";

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

      airpodsScript = pkgs.writeShellScript "waybar-airpods" ''
        result=$(${pkgs.local.airpods-status}/bin/airpods-status 2>/dev/null)
        class=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.class // "disconnected"' 2>/dev/null)
        if [ "$class" != "disconnected" ]; then
          echo "$result"
        fi
      '';

      btBatteryScript = pkgs.writeShellScript "waybar-bt-battery" ''
        while IFS= read -r line; do
          mac=$(echo "$line" | awk '{print $2}')
          battery=$(${pkgs.bluez}/bin/bluetoothctl info "$mac" 2>/dev/null \
            | grep "Battery Percentage" | grep -oE '\([0-9]+\)' | tr -d '()')
          if [ -n "$battery" ]; then
            printf '{"text": "󰥰 %s%%"}\n' "$battery"
            exit 0
          fi
        done < <(${pkgs.bluez}/bin/bluetoothctl devices Connected 2>/dev/null)
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
              ];
              modules-right =
                [ "tray" "custom/airpods" "custom/bt-battery" "custom/vpn" "network" ]
                ++ lib.optionals laptop [ "battery" ]
                ++ [ "disk" "memory" "clock" ]
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
                format = "{icon} {capacity}%";
                format-charging = "󱐋 {capacity}%";
                format-full = "{icon} full";
                format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
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
              "custom/airpods" = {
                exec = "${airpodsScript}";
                return-type = "json";
                interval = 30;
                format = "{}";
              };
              "custom/bt-battery" = {
                exec = "${btBatteryScript}";
                return-type = "json";
                interval = 30;
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

          #custom-airpods {
            color: ${c.cyan};
            padding: 0 6px;
          }

          #custom-bt-battery {
            color: ${c.cyan};
            padding: 0 6px;
          }
        '';
      };
    };
}
