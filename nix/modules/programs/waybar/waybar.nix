{ inputs, ... }:
{
  flake.modules.homeManager.waybar =
    {
      config,
      lib,
      pkgs,
      pkgsUnstable,
      hexToRgba,
      isLaptop,
      osConfig ? { },
      ...
    }:
    let
      c = config.theme;
      thermalPath = config.systemConstants.thermalZonePath;
      # claude-code is installed system-wide (profiles, live ISO)
      hasClaude = lib.any (p: lib.getName p == "claude-code") (
        osConfig.environment.systemPackages or [ ]
      );
      # Codex is installed system-wide by the host profiles.
      hasCodex = lib.any (p: lib.getName p == "codex") (osConfig.environment.systemPackages or [ ]);

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

              modules-left = [
                "sway/workspaces"
                "sway/mode"
                "tray"
              ];
              modules-right = [
                "idle_inhibitor"
                "mpris"
                "network"
              ]
              ++ lib.optionals isLaptop [ "battery" ]
              ++ [
                "disk"
                "memory"
              ]
              ++ lib.optionals hasClaude [ "custom/claude" ]
              ++ lib.optionals hasCodex [ "custom/codex" ]
              ++ [
                "clock"
              ]
              ++ lib.optionals (thermalPath != null) [ "temperature" ];

              # Keeps swayidle from locking/blanking (e.g. while watching mpv)
              idle_inhibitor = {
                format = "{icon}";
                format-icons = {
                  activated = "";
                  deactivated = "";
                };
              };

              # What mpv (yt) plays; hidden when nothing does.
              mpris = {
                format = "{status_icon} {title}";
                format-paused = "{status_icon} {title}";
                status-icons = {
                  playing = "▶";
                  paused = "⏸";
                };
                max-length = 40;
                ignored-players = [
                  "firefox"
                  "chromium"
                ];
              };

              tray = {
                icon-size = 14;
                spacing = 4;
              };

              "sway/workspaces" = {
                format = "{name}";
              };

              "sway/mode" = {
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
                states = {
                  low = 30;
                  critical = 10;
                };
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
            // lib.optionalAttrs hasClaude {
              "custom/claude" = {
                exec = lib.getExe pkgs.local.claude-usage;
                return-type = "json";
                interval = 300;
              };
            }
            // lib.optionalAttrs hasCodex {
              "custom/codex" = {
                exec = "CODEX_BIN=${lib.getExe pkgsUnstable.codex} ${lib.getExe pkgs.local.codex-usage}";
                return-type = "json";
                interval = 300;
              };
            }
            // lib.optionalAttrs (thermalPath != null) {
              # Built-in module: reads the millidegree file itself, no awk fork
              temperature = {
                hwmon-path = thermalPath;
                format = "{temperatureC} °C";
                interval = 15;
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
            background: ${c.accent};
            color: ${c.background};
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

          #battery.critical:not(.charging) {
            color: ${c.background};
            background-color: ${c.red};
          }

          #idle_inhibitor.activated {
            color: ${c.yellow};
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

          #custom-claude {
            color: ${c.foreground};
            padding: 0 6px;
          }

          #custom-claude.warning {
            color: ${c.yellow};
          }

          #custom-claude.critical {
            color: ${c.red};
          }

          #custom-claude.unknown {
            color: ${c.brightBlack};
          }

          #custom-codex {
            color: ${c.foreground};
            padding: 0 6px 0 24px;
            background-image: url("${inputs.self}/nix/assets/openai.svg");
            background-repeat: no-repeat;
            background-position: 4px center;
            background-size: 16px 16px;
          }

          #custom-codex.warning {
            color: ${c.yellow};
          }

          #custom-codex.critical {
            color: ${c.red};
          }

          #custom-codex.unknown {
            color: ${c.brightBlack};
          }

          #temperature {
            color: ${c.yellow};
            padding: 0 6px;
          }

        '';
      };
    };
}
