{ ... }:
{
  flake.modules.homeManager.hyprland =
    { config, lib, pkgs, mkModeNotif, ... }:
    let
      mod = "SUPER";
      isLaptop = config.systemConstants.system.type == "laptop";

      launchNotif = mkModeNotif {
        modeTitle = "Launch";
        bindings = [
          { key = "e"; description = "emacs"; }
          { key = "l"; description = "librewolf"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };

      powerNotif = mkModeNotif {
        modeTitle = "Power";
        bindings = [
          { key = "h"; description = "hibernate"; }
          { key = "r"; description = "reboot"; }
          { key = "s"; description = "shutdown"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };
    in
    {
      wayland.windowManager.hyprland.settings = {
        bind =
          [
            # Applications
            "${mod}, Return, exec, alacritty"
            "${mod} SHIFT, Q, killactive,"
            "${mod}, D, exec, wofi --show drun"

            # Focus (hy3)
            "${mod}, H, hy3:movefocus, l"
            "${mod}, J, hy3:movefocus, d"
            "${mod}, K, hy3:movefocus, u"
            "${mod}, L, hy3:movefocus, r"

            # Move windows (hy3)
            "${mod} SHIFT, H, hy3:movewindow, l"
            "${mod} SHIFT, J, hy3:movewindow, d"
            "${mod} SHIFT, K, hy3:movewindow, u"
            "${mod} SHIFT, L, hy3:movewindow, r"

            # Split direction (hy3) — mirrors i3 split h/v
            "${mod}, B, hy3:makegroup, h"
            "${mod}, V, hy3:makegroup, v"

            # Layout (hy3) — mirrors i3 s/e
            "${mod}, S, hy3:changegroup, tab"
            "${mod}, E, hy3:changegroup, opposite"

            "${mod} SHIFT, R, exec, hyprctl reload"

            # Screenshots
            ", Print, exec, screenshot-area"
            "${mod}, Print, exec, screenshot-full"

            # Submap triggers
            "${mod}, I, exec, ${launchNotif.enter}"
            "${mod}, I, submap, launch"
            "${mod} SHIFT, P, exec, ${powerNotif.enter}"
            "${mod} SHIFT, P, submap, power"
            "${mod}, R, submap, resize"
          ]
          ++ lib.genList (i: "${mod}, ${toString (i + 1)}, workspace, ${toString (i + 1)}") 9
          ++ lib.genList (i: "${mod} SHIFT, ${toString (i + 1)}, movetoworkspace, ${toString (i + 1)}") 9
          ++ lib.optionals isLaptop [
            ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
            ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
            "${mod}, XF86MonBrightnessUp, exec, brightnessctl --device='*kbd*' set +1"
            "${mod}, XF86MonBrightnessDown, exec, brightnessctl --device='*kbd*' set 1-"
          ];

        # Repeating binds (held down) for volume
        binde = [
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ];

        # Works even when screen is locked
        bindl = [
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ];
      };

      wayland.windowManager.hyprland.extraConfig = ''
        submap = launch
        bind = , E, exec, ${launchNotif.exit}
        bind = , E, exec, emacs
        bind = , E, submap, reset
        bind = , L, exec, ${launchNotif.exit}
        bind = , L, exec, librewolf
        bind = , L, submap, reset
        bind = , escape, exec, ${launchNotif.exit}
        bind = , escape, submap, reset
        bind = , space, exec, ${launchNotif.exit}
        bind = , space, submap, reset
        submap = reset

        submap = power
        bind = , H, exec, ${powerNotif.exit}
        bind = , H, exec, systemctl hibernate
        bind = , H, submap, reset
        bind = , R, exec, ${powerNotif.exit}
        bind = , R, exec, systemctl reboot
        bind = , R, submap, reset
        bind = , S, exec, ${powerNotif.exit}
        bind = , S, exec, systemctl poweroff
        bind = , S, submap, reset
        bind = , escape, exec, ${powerNotif.exit}
        bind = , escape, submap, reset
        bind = , space, exec, ${powerNotif.exit}
        bind = , space, submap, reset
        submap = reset

        submap = resize
        binde = , H, resizeactive, -20 0
        binde = , J, resizeactive, 0 20
        binde = , K, resizeactive, 0 -20
        binde = , L, resizeactive, 20 0
        bind = , escape, submap, reset
        bind = , space, submap, reset
        submap = reset
      '';
    };
}
