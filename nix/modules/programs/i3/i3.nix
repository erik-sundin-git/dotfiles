{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      home.packages =
        [ pkgs.blueman ]
        ++ lib.optionals (config.systemConstants.currentSystemType == "laptop") [
          pkgs.brightnessctl
        ];

      services.redshift = {
        enable = true;
        latitude = config.systemConstants.latitude;
        longitude = config.systemConstants.longitude;
        temperature.day = 6500;
        temperature.night = 3500;
      };

      xsession.windowManager.i3 = {
        enable = true;

        config = {
          modifier = "Mod4";

          startup = [
            { command = "nitrogen --restore"; }
            { command = "blueman-applet"; notification = false; }
            { command = "systemctl --user import-environment DISPLAY XAUTHORITY"; notification = false; }
          ];

          gaps = {
            inner = 0;
            outer = 0;
            top = 0;
          };

          bars = [
            {
              fonts = {
                size = 10.0;
              };
              position = "bottom";
              statusCommand = "i3status";
            }
          ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "1";
        };
      };
    };
}
