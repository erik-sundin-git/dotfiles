{ ... }:
{
  # Sway / Wayland: swaylock + swayidle. Locking is triggered by
  # `loginctl lock-session` (bound to mod+Ctrl+l in swayBindingsData), which
  # systemd-logind forwards over D-Bus; swayidle catches it and runs swaylock.
  flake.modules.homeManager.swayLock =
    { config, pkgs, lib, isLaptop, ... }:
    let
      c = config.theme;
      hex = lib.removePrefix "#";
      swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
    in
    {
      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          color = hex c.background;
          font-size = 24;
          indicator-radius = 100;
          indicator-thickness = 8;
          ring-color = hex c.blue;
          key-hl-color = hex c.green;
          bs-hl-color = hex c.red;
          inside-color = hex c.background;
          text-color = hex c.foreground;
          separator-color = "00000000";
          fade-in = "0.2";
          effect-blur = "8x3";
          ignore-empty-password = true;
          show-failed-attempts = true;
        };
      };

      services.swayidle = {
        enable = true;
        events = [
          { event = "before-sleep"; command = "${swaylock} -f"; }
          { event = "lock"; command = "${swaylock} -f"; }
        ];
        timeouts =
          [
            { timeout = 1200; command = "${swaylock} -f"; }
          ]
          ++ lib.optional isLaptop {
            timeout = 1800;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          };
      };
    };

  # Hyprland: hyprlock + hypridle. Same loginctl lock-session flow.
  flake.modules.homeManager.hyprlandLock =
    { config, pkgs, lib, isLaptop, hexToHyprRgb, ... }:
    let
      c = config.theme;
    in
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            grace = 0;
            hide_cursor = true;
            no_fade_in = false;
          };
          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
            }
          ];
          input-field = [
            {
              size = "300, 60";
              position = "0, -80";
              halign = "center";
              valign = "center";
              outline_thickness = 3;
              dots_size = 0.25;
              dots_spacing = 0.35;
              outer_color = hexToHyprRgb c.blue;
              inner_color = hexToHyprRgb c.background;
              font_color = hexToHyprRgb c.foreground;
              fail_color = hexToHyprRgb c.red;
              check_color = hexToHyprRgb c.green;
              placeholder_text = "<i>Password…</i>";
              fade_on_empty = false;
            }
          ];
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener =
            [
              {
                timeout = 1200;
                on-timeout = "loginctl lock-session";
              }
            ]
            ++ lib.optional isLaptop {
              timeout = 1800;
              on-timeout = "systemctl suspend";
            };
        };
      };
    };

  # i3 / X11: services.screen-locker wraps xss-lock + i3lock, so
  # loginctl lock-session locks; xautolock adds inactivity timeout.
  flake.modules.homeManager.i3Lock =
    { config, pkgs, lib, isLaptop, ... }:
    let
      c = config.theme;
      hex = lib.removePrefix "#";
      lockCmd = "${pkgs.i3lock-color}/bin/i3lock-color --color=${hex c.background} --clock --insidecolor=${hex c.background}ff --ringcolor=${hex c.blue}ff --keyhlcolor=${hex c.green}ff --bshlcolor=${hex c.red}ff --textcolor=${hex c.foreground}ff --nofork";
    in
    {
      home.packages = [ pkgs.i3lock-color ];

      services.screen-locker = {
        enable = true;
        lockCmd = lockCmd;
        inactiveInterval = 20;
        xautolock.enable = isLaptop;
        xss-lock.extraOptions = [ "--ignore-sleep" ];
      };
    };
}
