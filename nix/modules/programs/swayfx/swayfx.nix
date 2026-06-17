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
      ...
    }:
    let
      kb = config.systemConstants.keyboard;
      isLaptop = config.systemConstants.system.type == "laptop";
      wallpaper = config.systemConstants.wallpaper;
    in
    {
      imports = with inputs.self.modules.homeManager; [
        uiHelpers
        waylandBase
      ];

      wayland.windowManager.sway = {
        enable = true;
        package = pkgs.swayfx;
        systemd.enable = true;
        # pam_systemd activates graphical-session.target at login (before sway
        # runs), so waybar.service gets triggered and skipped via
        # ConditionEnvironment=WAYLAND_DISPLAY before env is imported. Start
        # it manually after dbus-update-activation-environment.
        systemd.extraCommands = lib.mkBefore [ "systemctl --user start waybar.service" ];
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

          startup = [
            { command = "swayosd-server"; }
            { command = "dunst"; }
            { command = "proton-mail"; }
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

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec sway
        fi
      '';
    };
}
