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
        package = null;

        config = {

          floating.criteria = [

          ];

          modifier = "Mod4";

          gaps = {
            inner = 0;
            outer = 0;
            top = 0;
          };

          fonts = {

          };

          bars = [
            {
              fonts = {
                size = 13.0;
              };
              position = "bot";
              statusCommand = "i3status";
            }
          ];

          workspaceAutoBackAndForth = true;
          defaultWorkspace = "1";
          startup = [
            { command = "nitrogen --restore"; }
          ];
        };
      };
    };
}
