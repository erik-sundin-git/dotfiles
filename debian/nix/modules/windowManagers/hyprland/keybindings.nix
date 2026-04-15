{ ... }:

let
  # [1 2 3 4 5 6 7 8 9]
  n1to9 = builtins.genList (i: i + 1) 9;

  workspaceBinds =
    map (n: "$mainMod, ${toString n}, workspace, ${toString n}") n1to9
    ++ [ "$mainMod, 0, workspace, 10" ];

  moveWorkspaceBinds =
    map (n: "$mainMod SHIFT, ${toString n}, movetoworkspace, ${toString n}") n1to9
    ++ [ "$mainMod SHIFT, 0, movetoworkspace, 10" ];

  persistentWorkspaces =
    map (n: "${toString n}, persistent:true") (builtins.genList (i: i + 1) 4)
    ++ [
      "5, persistent:true, on-created-empty:alacritty"
      "6, persistent:true"
    ];
in

{
  flake.modules.homeManager.hyprland-keybindings =
    { ... }:
    {
      wayland.windowManager.hyprland = {
        settings = {
          bind =
            [
              "$mainMod, Return, exec, $terminal"
              "$mainMod$Shift_L, Q, killactive,"
              "$mainMod, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
              "$mainMod, E, exec, $fileManager"
              "$mainMod$Shift_L, V, togglefloating,"
              "$mainMod, D, exec, $menu"
              "$mainMod, P, pseudo,"
              "$mainMod, V, layoutmsg, togglesplit"
              "$mainMod, h, movefocus, l"
              "$mainMod, l, movefocus, r"
              "$mainMod, j, movefocus, u"
              "$mainMod, k, movefocus, d"
              "$mainMod SHIFT, h, movewindow, l"
              "$mainMod SHIFT, l, movewindow, r"
              "$mainMod SHIFT, k, movewindow, u"
              "$mainMod SHIFT, j, movewindow, d"
            ]
            ++ workspaceBinds
            ++ moveWorkspaceBinds
            ++ [
              "$mainMod, S, togglespecialworkspace, magic"
              "$mainMod SHIFT, S, movetoworkspace, special:magic"
              "$mainMod, R, submap, resize"
            ];

          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          bindel = [
            ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
            ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
          ];

          bindl = [
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
          ];

          workspace = persistentWorkspaces;
        };

        submaps = {
          resize.settings = {
            binde = [
              ", l, resizeactive, 20 0"
              ", h, resizeactive, -20 0"
              ", k, resizeactive, 0 -20"
              ", j, resizeactive, 0 20"
            ];
            bind = [
              ", return, submap, reset"
              ", space, submap, reset"
            ];
          };
        };
      };
    };
}
