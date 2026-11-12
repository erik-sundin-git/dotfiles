{ inputs, ... }:
{
  flake.modules.nixos.swayfx =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.self.modules.nixos.waylandBase ];

      programs.sway.enable = true;
      programs.sway.package = pkgs.swayfx;

      # xdg-desktop-portal-wlr crash-loops without PipeWire, which stalls
      # xdg-desktop-portal startup and makes waybar time out (~25s per try)
      xdg.portal.wlr.enable = lib.mkForce config.services.pipewire.enable;

      # sway refuses to start on the proprietary NVIDIA driver without
      # --unsupported-gpu, so LightDM would just loop. install-host greys the
      # -nvidia hardware modules out; this catches hand-written hosts that
      # haven't opted in (xps does, rendering on the iGPU).
      assertions = [
        {
          assertion =
            !lib.elem "nvidia" config.services.xserver.videoDrivers
            || lib.any (u: lib.elem "--unsupported-gpu" u.wayland.windowManager.sway.extraOptions) (
              lib.attrValues (config.home-manager.users or { })
            );
          message = "SwayFX doesn't run on the proprietary NVIDIA driver: use an X11 stack, a nixos-hardware module without -nvidia (e.g. an -intel variant), or pass --unsupported-gpu in HM's wayland.windowManager.sway.extraOptions.";
        }
      ];
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
        # HM's default package applies these through the wrapper's override;
        # a bare pkgs.swayfx would silently ignore them
        package = pkgs.swayfx.override {
          inherit (config.wayland.windowManager.sway) extraOptions extraSessionCommands;
          withBaseWrapper = config.wayland.windowManager.sway.wrapperFeatures.base;
          withGtkWrapper = config.wayland.windowManager.sway.wrapperFeatures.gtk;
        };
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
          ${lib.optionalString t.blur "blur enable\nblur_passes 2\nblur_radius 6\nlayer_effects \"waybar\" blur enable\nlayer_effects \"launcher\" blur enable"}
          corner_radius ${toString t.rounding}
          default_dim_inactive ${toString t.dimInactive}
          shadows disable

          ${lib.optionalString isLaptop ''
            # Docked with the lid shut: turn the panel off so workspaces move
            # to the external monitor (undocked, logind suspends anyway)
            bindswitch --reload --locked lid:on output eDP-1 disable
            bindswitch --reload --locked lid:off output eDP-1 enable
          ''}
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
