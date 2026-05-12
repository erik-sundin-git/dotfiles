{ inputs, ... }:
{
  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      c = config.theme;
      isLaptop = config.systemConstants.system.type == "laptop";
      wallpaper = "${inputs.self}/Pictures/Nasa/Artemis II/art002e012673.jpg";
    in
    {
      imports = [ inputs.self.modules.homeManager.uiHelpers ];

      wayland.windowManager.hyprland = {
        enable = true;
        plugins = [ pkgs.hyprlandPlugins.hy3 ];

        settings = {
          general = {
            layout = "hy3";
            gaps_in = 0;
            gaps_out = 0;
            border_size = 2;
            "col.active_border" = "rgb(${lib.removePrefix "#" c.blue})";
            "col.inactive_border" = "rgb(${lib.removePrefix "#" c.black})";
          };

          decoration = {
            rounding = 8;
            active_opacity = 1.0;
            inactive_opacity = 0.9;
            blur = {
              enabled = true;
              size = 6;
              passes = 2;
              new_optimizations = true;
            };
            shadow.enabled = false;
          };

          animations = {
            enabled = true;
            bezier = "ease, 0.4, 0.0, 0.2, 1.0";
            animation = [
              "windows, 1, 3, ease, slide"
              "fade, 1, 3, ease"
              "workspaces, 1, 4, ease, slidevert"
            ];
          };

          input = {
            kb_layout = "se";
            kb_options = "ctrl:swapcaps";
            accel_profile = "flat";
            sensitivity = 0.0;
          }
          // lib.optionalAttrs isLaptop {
            touchpad = {
              tap-to-click = true;
              natural_scroll = false;
            };
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            focus_on_activate = true;
          };

          "exec-once" = [
            "swayosd-server"
            "blueman-applet"
            "waybar"
            "dunst"
            "hyprpaper"
          ];
        };
      };

      xdg.configFile."hypr/hyprpaper.conf".text = ''
        preload = ${wallpaper}
        wallpaper = ,${wallpaper}
        splash = false
      '';

      programs.emacs.package = pkgs.emacs-git-pgtk;

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec Hyprland
        fi
      '';
    };
}
