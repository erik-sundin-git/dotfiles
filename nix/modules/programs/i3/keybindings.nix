{ ... }:
{
  flake.modules.homeManager.i3 =
    { config, lib, ... }:
    let
      modifier = config.xsession.windowManager.i3.config.modifier;
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
        {
          "${modifier}+Return" = "exec alacritty";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+d" = "exec --no-startup-id dmenu_run";

          "${modifier}+m" = "workspace mail";
          "${modifier}+Shift+m" = "move container to workspace mail";

          "${modifier}+e" = "workspace emacs";
          "${modifier}+Shift+e" = "move container to workspace emacs";

          "${modifier}+b" = "splith";
          "${modifier}+v" = "splitv";

          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";

          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";

          # Screenshots
          "Print" = "exec --no-startup-id screenshot-area";
          "${modifier}+Print" = "exec --no-startup-id screenshot-full";

          # Volume
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        }
        // lib.listToAttrs (
          lib.genList (i: {
            name = "${modifier}+${toString (i + 1)}";
            value = "workspace number ${toString (i + 1)}";
          }) 9
        )
        // lib.listToAttrs (
          lib.genList (i: {
            name = "${modifier}+Shift+${toString (i + 1)}";
            value = "move container to workspace number ${toString (i + 1)}";
          }) 9
        )
        // lib.optionalAttrs isLaptop {
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

          # Keyboard backlight
          "${modifier}+XF86MonBrightnessUp" = "exec brightnessctl --device='*kbd*' set +1";
          "${modifier}+XF86MonBrightnessDown" = "exec brightnessctl --device='*kbd*' set 1-";
        }
      );
    };
}
