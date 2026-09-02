{ ... }:
{
  flake.modules.homeManager.swayfx =
    { config, lib, ... }:
    let
      modifier = config.wayland.windowManager.sway.config.modifier;
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault (
        {
          "${modifier}+Return" = "exec alacritty";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+d" = "exec wofi --show drun";
          "${modifier}+Shift+a" = "exec nix-add-package";
          "${modifier}+F1" = "exec sway-help";

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
          "Print" = "exec screenshot-area";
          "${modifier}+Print" = "exec screenshot-full";

          # Volume
          "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
          "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
          "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
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
          "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
          "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";

          "${modifier}+XF86MonBrightnessUp" = "exec brightnessctl --device='*kbd*' set +1";
          "${modifier}+XF86MonBrightnessDown" = "exec brightnessctl --device='*kbd*' set 1-";
        }
      );
    };
}
