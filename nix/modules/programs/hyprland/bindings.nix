{ ... }:
{
  flake.modules.homeManager.hyprland =
    { config, lib, pkgs, ... }:
    let
      mod = "SUPER";
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      wayland.windowManager.hyprland.settings = {
        bind =
          [
            # Applications
            "${mod}, Return, exec, alacritty"
            "${mod} SHIFT, Q, killactive,"
            "${mod}, D, exec, wofi --show drun"
            "${mod} SHIFT, Space, togglefloating,"

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

        # Mouse binds for floating windows
        bindm = [
          "${mod}, mouse:272, movewindow"
        ];
      };

    };
}
