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
      xsession.windowManager.i3 = {
        enable = true;

        config = {
          modifier = "Mod4";

          startup = [
            { command = "nitrogen --restore"; }
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
