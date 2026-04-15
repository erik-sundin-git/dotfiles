{ inputs, ... }:

{
  flake.modules.homeManager.hyprland =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hyprland-keybindings
        hyprland-windowrules
      ];

      wayland.windowManager.hyprland = {
        enable = true;

        settings = {
          monitor = ",preferred,auto,auto";

          "$terminal" = "alacritty";
          "$fileManager" = "nautilus";
          "$menu" = "wofi --show drun";
          "$mainMod" = "SUPER";

          exec-once = [
            "hyprpm reload -n"
            "nm-applet &"
            "waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &"
            "hyprpaper"
            "dunst"
          ];

          env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
          ];

          general = {
            gaps_in = 5;
            gaps_out = 5;
            border_size = 1;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 3;
            rounding_power = 2;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          animations = {
            enabled = "yes, please :)";
            bezier = [
              "easeOutQuint,   0.23, 1,    0.32, 1"
              "easeInOutCubic, 0.65, 0.05, 0.36, 1"
              "linear,         0,    0,    1,    1"
              "almostLinear,   0.5,  0.5,  0.75, 1"
              "quick,          0.15, 0,    0.1,  1"
            ];
            animation = [
              "global,        1,     10,    default"
              "border,        1,     5.39,  easeOutQuint"
              "windows,       1,     4.79,  easeOutQuint"
              "windowsIn,     1,     4.1,   easeOutQuint, popin 87%"
              "windowsOut,    1,     1.49,  linear,       popin 87%"
              "fadeIn,        1,     1.73,  almostLinear"
              "fadeOut,       1,     1.46,  almostLinear"
              "fade,          1,     3.03,  quick"
              "layers,        1,     3.81,  easeOutQuint"
              "layersIn,      1,     4,     easeOutQuint, fade"
              "layersOut,     1,     1.5,   linear,       fade"
              "fadeLayersIn,  1,     1.79,  almostLinear"
              "fadeLayersOut, 1,     1.39,  almostLinear"
              "workspaces,    1,     1.94,  almostLinear, fade"
              "workspacesIn,  1,     1.21,  almostLinear, fade"
              "workspacesOut, 1,     1.94,  almostLinear, fade"
              "zoomFactor,    1,     7,     quick"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          master = {
            new_status = "master";
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          input = {
            kb_layout = "se";
            kb_variant = "";
            kb_model = "";
            kb_options = "ctrl:swapcaps";
            kb_rules = "";
            sensitivity = 0;
            touchpad = {
              natural_scroll = false;
              disable_while_typing = true;
              clickfinger_behavior = true;
            };
          };

          gesture = "3, horizontal, workspace";

          device = {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          };
        };
      };
    };
}
