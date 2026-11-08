{ ... }:
{
  flake.modules.homeManager.gammastep =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      target = [ config.wayland.systemd.target ];
    in
    {
      services.gammastep = {
        enable = true;
        dawnTime = "07:00";
        duskTime = "21:00";
        temperature.day = 6500;
        temperature.night = 2500;
      };

      # HM binds it to graphical-session.target, which comes up before sway
      # exports WAYLAND_DISPLAY and never stops (see CLAUDE.md). The wayland
      # target is sway-session.target under sway, graphical-session.target
      # elsewhere (EXWM).
      systemd.user.services.gammastep = {
        Unit.After = lib.mkForce target;
        Unit.PartOf = lib.mkForce target;
        Install.WantedBy = lib.mkForce target;
      };

      # Stopping the service restores normal gamma; starting it reapplies the
      # schedule. Bound in sway's options mode.
      home.packages = [
        (pkgs.writeShellApplication {
          name = "gammastep-toggle";
          runtimeInputs = [
            pkgs.libnotify
            pkgs.systemd
          ];
          text = ''
            if systemctl --user is-active --quiet gammastep; then
              systemctl --user stop gammastep
              notify-send -u low Gammastep off
            else
              systemctl --user start gammastep
              notify-send -u low Gammastep on
            fi
          '';
        })
      ];
    };
}
