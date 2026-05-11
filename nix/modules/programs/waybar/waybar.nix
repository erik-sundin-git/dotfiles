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
                [ "tray" "network" ]
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

          #battery.low {
            color: ${c.red};
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
        '';
      };
    };
}
