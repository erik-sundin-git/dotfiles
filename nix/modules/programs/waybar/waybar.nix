{ ... }:
{
  flake.modules.homeManager.waybar =
    {
      config,
      lib,
      pkgs,
      hexToRgba,
      isLaptop,
      ...
    }:
    let
      c = config.theme;
      thermalPath = config.systemConstants.thermalZonePath;
      isHyprland = config.wayland.windowManager.hyprland.enable;

      tempScript = pkgs.writeShellScript "waybar-temp" ''
        ${pkgs.gawk}/bin/awk '{printf "%.0f °C", $1/1000}' ${thermalPath}
      '';

    in
    {
      # HM's on-failure treats SIGTERM as a clean exit, so an earlyoom kill
      # would leave the bar gone for the rest of the session
      systemd.user.services.waybar.Service.Restart = lib.mkForce "always";

      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings = [
          (
            {
              position = "bottom";
              height = 24;
              spacing = 4;

              modules-left =
                (
                  if isHyprland then
                    [
                      "hyprland/workspaces"
                      "hyprland/submap"
                    ]
                  else
                    [
                      "sway/workspaces"
                      "sway/mode"
                    ]
                )
                ++ [ "tray" ];
              modules-right = [
                "network"
              ]
              ++ lib.optionals isLaptop [ "battery" ]
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

              "sway/workspaces" = lib.mkIf (!isHyprland) {
                format = "{name}";
              };

              "sway/mode" = lib.mkIf (!isHyprland) {
                format = "{}";
              };

              network = {
                format-wifi = "W: {essid}";
                format-ethernet = "E: {ipaddr}";
                format-disconnected = "down";
                interval = 15;
              };

              battery = {
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
                interval = 15;
              };

              clock = {
                format = "{:%Y-%m-%d %H:%M}";
                interval = 60;
              };
            }
            // lib.optionalAttrs (thermalPath != null) {
              "custom/temperature" = {
                exec = "${tempScript}";
                interval = 15;
                format = "{}";
              };
            }
          )
        ];

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "${c.fontFamily}";
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: ${hexToRgba c.superDark (if c.blur then "0.5" else "1.0")};
            color: ${c.foreground};
          }

          #workspaces button {
            color: ${c.brightBlack};
            padding: 0 4px;
            background: transparent;
            border-radius: ${toString (c.rounding / 2)}px;
          }

          #workspaces button.active,
          #workspaces button.focused {
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

        '';
      };
    };
}
