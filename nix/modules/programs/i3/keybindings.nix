{ ... }:
{
  flake.modules.homeManager.i3 =
    { config, lib, pkgs, ... }:
    let
      layoutLeftStack = pkgs.writeShellApplication {
        name = "i3-layout-left-stack";
        runtimeInputs = [ pkgs.jq pkgs.i3 ];
        text = ''
          TREE=$(i3-msg -t get_tree)

          WS=$(echo "$TREE" | jq -r '
            first(.. | select(type == "object") | select(.type? == "workspace") | select(.focused? == true) | .name)
          ')

          FOCUSED=$(echo "$TREE" | jq '
            first(.. | select(type == "object") | select(.focused? == true) | select(.window? != null) | .id)
          ')

          [ -z "$FOCUSED" ] || [ "$FOCUSED" = "null" ] && exit 0

          WINS=$(echo "$TREE" | jq -r --arg ws "$WS" '
            first(.. | select(type == "object") | select(.type? == "workspace") | select(.name == $ws)) |
            [.. | select(type == "object") | select(.type? == "con") | select(.window? != null) | .id] | .[]
          ')

          OTHERS=$(echo "$WINS" | grep -v "^$FOCUSED$" || true)
          [ -z "$OTHERS" ] && exit 0

          TEMP="__layout_tmp"

          for WID in $OTHERS; do
            i3-msg "[con_id=$WID] move to workspace $TEMP" >/dev/null
          done

          i3-msg "[con_id=$FOCUSED] focus" >/dev/null
          i3-msg "split h" >/dev/null

          FIRST=$(echo "$OTHERS" | head -1)
          REST=$(echo "$OTHERS" | tail -n +2 || true)

          i3-msg "[con_id=$FIRST] move to workspace \"$WS\"" >/dev/null
          i3-msg "[con_id=$FIRST] focus; layout stacking" >/dev/null

          for WID in $REST; do
            i3-msg "[con_id=$WID] move to workspace \"$WS\"" >/dev/null
          done

          i3-msg "[con_id=$FOCUSED] focus" >/dev/null
        '';
      };
    in
    {
      home.packages = [ layoutLeftStack ];

      xsession.windowManager.i3.config = {
        keybindings =
          let
            modifier = config.xsession.windowManager.i3.config.modifier;
            isLaptop = config.systemConstants.system.type == "laptop";
          in
          lib.mkOptionDefault (
            {
              "${modifier}+Return" = "exec alacritty";
              "${modifier}+Shift+q" = "kill";
              "${modifier}+d" = "exec --no-startup-id dmenu_run";

              "${modifier}+t" = "exec --no-startup-id ${layoutLeftStack}/bin/i3-layout-left-stack";

              "${modifier}+b" = "split h";
              "${modifier}+v" = "split v";

              "${modifier}+h" = "focus left";
              "${modifier}+j" = "focus down";
              "${modifier}+k" = "focus up";
              "${modifier}+l" = "focus right";

              "${modifier}+shift+h" = "move left";
              "${modifier}+shift+j" = "move down";
              "${modifier}+shift+k" = "move up";
              "${modifier}+shift+l" = "move right";

              # Screenshots
              "Print" = "exec --no-startup-id screenshot-area";
              "${modifier}+Print" = "exec --no-startup-id screenshot-full";

              # Media controls
              "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
              "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
              "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
            }
            // lib.optionalAttrs isLaptop {
              "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
              "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

              # Keyboard backlight
              "${modifier}+XF86MonBrightnessUp" = "exec brightnessctl --device='*kbd*' set +1";
              "${modifier}+XF86MonBrightnessDown" = "exec brightnessctl --device='*kbd*' set 1-";
            }
          );
      };
    };
}
