{ inputs, ... }:
{
  flake.modules.nixos.hyprland =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.waylandBase ];

      programs.hyprland.enable = true;
      programs.hyprland.withUWSM = true;
      programs.hyprland.xwayland.enable = true;

      xdg.portal.configPackages = [ pkgs.xdg-desktop-portal-hyprland ];
    };

  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      hexToHyprRgb,
      ...
    }:
    let
      c = config.theme;
      kb = config.systemConstants.keyboard;
      isLaptop = config.systemConstants.system.type == "laptop";
      wallpaper = config.systemConstants.wallpaper;
    in
    {
      imports = [ inputs.self.modules.homeManager.uiHelpers ];

      wayland.windowManager.hyprland = {
        enable = true;
        plugins = [ pkgs.hyprlandPlugins.hy3 ];
        systemd.enable = false;

        settings = {
          general = {
            layout = "hy3";
            gaps_in = 0;
            gaps_out = 0;
            border_size = 2;
            "col.active_border" = hexToHyprRgb c.blue;
            "col.inactive_border" = hexToHyprRgb c.black;
          };

          decoration = {
            rounding = 8;
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
            kb_layout = kb.layout;
            kb_options = kb.options;
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
            "systemctl --user start hyprpolkitagent"
            "swayosd-server"
            "waybar"
            "dunst"
            "${pkgs.swaybg}/bin/swaybg -i '${wallpaper}' -m fill"
          ];
        };
      };

      programs.emacs.package = pkgs.emacs-pgtk;

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      '';
    };
}
