{ ... }:
{
  flake.modules.homeManager.gammastep =
    { pkgs, ... }:
    {
      services.gammastep = {
        enable = true;
        dawnTime = "07:00";
        duskTime = "21:00";
        temperature.day = 6500;
        temperature.night = 2500;
      };

      # Stopping the service restores normal gamma; starting it reapplies the
      # schedule. Bound in sway's options mode.
      home.packages = [
        (pkgs.writeShellApplication {
          name = "gammastep-toggle";
          runtimeInputs = [ pkgs.libnotify ];
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
