{ inputs, ... }:
{
  flake.modules.nixos.swayfx =
    { pkgs, ... }:
    {
      programs.sway.enable = true;
      programs.sway.package = pkgs.swayfx;

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };

  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      mkColors,
      ...
    }:
    let
      c = config.theme;
      isLaptop = config.systemConstants.system.type == "laptop";
      wallpaper = "${inputs.self}/Pictures/landscapes/mountain_landscape_1.jpg";
    in
    {
      imports = [ inputs.self.modules.homeManager.uiHelpers ];

      wayland.windowManager.sway = {
        enable = true;
        package = pkgs.swayfx;
        systemd.enable = true;
        checkConfig = false;

        config = {
          modifier = "Mod4";
          bars = [ ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "workspace number 1";

          gaps = {
            inner = 0;
            outer = 0;
          };

          window.border = 2;
          floating.border = 2;

          colors = {
            focused = mkColors {
              border = c.blue;
              text = c.black;
              indicator = c.cyan;
            };
            focusedInactive = mkColors {
              border = c.black;
              text = c.foreground;
            };
            unfocused = mkColors {
              border = c.black;
              background = c.background;
              text = c.brightBlack;
            };
            urgent = mkColors {
              border = c.red;
              text = c.brightWhite;
            };
          };

          startup = [
            { command = "swayosd-server"; }
            { command = "waybar"; }
            { command = "dunst"; }
            { command = "${pkgs.swaybg}/bin/swaybg -i '${wallpaper}' -m fill"; }
          ];

          input = {
            "*" = {
              xkb_layout = "se";
              xkb_options = "ctrl:swapcaps";
              accel_profile = "flat";
              pointer_accel = "0";
            };
          } // lib.optionalAttrs isLaptop {
            "type:touchpad" = {
              tap = "enabled";
              natural_scroll = "disabled";
            };
          };

          output."*".bg = "'${wallpaper}' fill";
        };

        extraConfig = ''
          blur enable
          blur_passes 2
          blur_radius 6
          corner_radius 8
          default_dim_inactive 0.1
          shadows disable
        '';
      };

      programs.emacs.package = pkgs.emacs-git-pgtk;

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec sway
        fi
      '';
    };
}
