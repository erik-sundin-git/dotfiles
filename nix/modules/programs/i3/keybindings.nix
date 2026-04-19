{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  flake.modules.homeManager.i3 = {config, lib, ...}: {
    xsession.windowManager.i3.config = {
      keybindings =
        let
          modifier = config.xsession.windowManager.i3.config.modifier;
          isLaptop = config.systemConstants.currentSystemType == "laptop";
        in
        lib.mkOptionDefault (
          {
            "${modifier}+Return" = "exec alacritty";
            "${modifier}+Shift+q" = "kill";
            "${modifier}+d" = "exec --no-startup-id dmenu_run";

            "${modifier}+h" = "focus left";
            "${modifier}+j" = "focus down";
            "${modifier}+k" = "focus up";
            "${modifier}+l" = "focus right";

            "${modifier}+shift+h" = "move left";
            "${modifier}+shift+j" = "move down";
            "${modifier}+shift+k" = "move up";
            "${modifier}+shift+l" = "move right";

            # Media controls
            "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMute" = " exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          }
          // lib.optionalAttrs isLaptop {
            "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
            "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          }
        );
    };
  };
}
