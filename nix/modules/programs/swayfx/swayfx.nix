{ inputs, ... }:
{
  flake.modules.nixos.swayfx =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.waylandBase ];

      programs.sway.enable = true;
      programs.sway.package = pkgs.swayfx;

      xdg.portal.wlr.enable = true;
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
      kb = config.systemConstants.keyboard;
      isLaptop = config.systemConstants.system.type == "laptop";
      wallpaper = config.systemConstants.wallpaper;
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

          window.commands = [
            {
              criteria.app_id = "firefox";
              command = "border pixel 2";
            }
            {
              criteria.app_id = "librewolf";
              command = "border pixel 2";
            }
            {
              criteria.app_id = "chromium";
              command = "border pixel 2";
            }
            {
              criteria.app_id = "ungoogled-chromium";
              command = "border pixel 2";
            }
            {
              criteria.app_id = "FreeTube";
              command = "border pixel 2";
            }
          ];

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
            { command = "dunst"; }
            { command = "${pkgs.swaybg}/bin/swaybg -i '${wallpaper}' -m fill"; }
          ];

          input = {
            "*" = {
              xkb_layout = kb.layout;
              xkb_options = kb.options;
              accel_profile = "flat";
              pointer_accel = "0";
            };
          }
          // lib.optionalAttrs isLaptop {
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

      programs.emacs.package = pkgs.emacs-pgtk;

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec sway
        fi
      '';
    };
}
