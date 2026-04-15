{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  flake.modules.homeManager.windowManagers.i3 = {
    config.keybindings = {
      keybindings =
        let
          modifier = config.xsession.windowManager.i3.config.modifier;
        in
        lib.mkOptionDefault {
          "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show drun";

          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";

          "${modifier}+shift+h" = "move left";
          "${modifier}+shift+j" = "move down";
          "${modifier}+shift+k" = "move up";
          "${modifier}+shift+l" = "move right";

          "${modifier}+shift+s" = "exec rofi-power";

          # Media controls
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = " exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };
    };
  };
}
