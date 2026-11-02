{ inputs, ... }:
{
  flake.modules.nixos.swayfx =
    { config, lib, pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.waylandBase ];

      programs.sway.enable = true;
      programs.sway.package = pkgs.swayfx;

      # xdg-desktop-portal-wlr crash-loops without PipeWire, which stalls
      # xdg-desktop-portal startup and makes waybar time out (~25s per try)
      xdg.portal.wlr.enable = lib.mkForce config.services.pipewire.enable;
    };

  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      isLaptop,
      mkPolkitAgent,
      ...
    }:
    let
      kb = config.systemConstants.keyboard;
      wallpaper = config.systemConstants.wallpaper;
      t = config.theme;
    in
    {
      imports = with inputs.self.modules.homeManager; [
        uiHelpers
        waylandBase
        swayBindings
        claudeLaunchers
      ];

      # NixOS's session wrapper starts nixos-fake-graphical-session.target for
      # sway (not on its systemd-aware list) and never stops it, so
      # graphical-session.target is up before sway has exported WAYLAND_DISPLAY
      # and stays up after it exits. Bind waybar, swayosd and swayidle to
      # sway-session.target instead: HM's default extraCommands start it after
      # the env import and stop it when sway exits.
      wayland.systemd.target = "sway-session.target";

      systemd.user.services.polkit-agent = mkPolkitAgent config.wayland.systemd.target;

      # Nothing else starts the applet on sway (i3 execs it); without it the
      # tray icon and blueman's auto-connect only appear once blueman-manager
      # D-Bus-activates it.
      services.blueman-applet = {
        enable = true;
        systemdTargets = [ config.wayland.systemd.target ];
      };

      wayland.windowManager.sway = {
        enable = true;
        package = pkgs.swayfx;
        systemd.enable = true;
        systemd.dbusImplementation = "broker";
        checkConfig = false;

        config = {
          modifier = "Mod4";
          bars = [ ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "workspace number 1";

          gaps = {
            inner = t.gaps;
            outer = t.gaps;
          };

          window.border = 2;
          floating.border = 2;

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
          ${lib.optionalString t.blur "blur enable\nblur_passes 2\nblur_radius 6\nlayer_effects \"waybar\" blur enable\nlayer_effects \"wofi\" blur enable"}
          corner_radius ${toString t.rounding}
          default_dim_inactive ${toString t.dimInactive}
          shadows disable

          for_window [app_id="ai-add-pkg"] floating enable, resize set 1000 720, move position center
          for_window [app_id="ai-prompt"] floating enable, resize set 1000 720, move position center
        '';
      };

      programs.bash.profileExtra = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec sway
        fi
      '';
    };
}
