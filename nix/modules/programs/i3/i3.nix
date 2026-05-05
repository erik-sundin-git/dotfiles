{ inputs, ... }:
{
  flake.modules.homeManager.i3 =
    {
      config,
      mkColors,
      ...
    }:
    let
      c = config.theme;
    in
    {
      imports = [ inputs.self.modules.homeManager.uiHelpers ];

      xsession.windowManager.i3 = {
        enable = true;

        config = {
          modifier = "Mod4";

          startup = [
            { command = "nitrogen --restore"; notification = false; }
            {
              command = "blueman-applet";
              notification = false;
            }
            {
              command = "systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS && systemctl --user restart xdg-desktop-portal-gtk xdg-desktop-portal";
              notification = false;
            }
            {
              command = "pkill polybar; polybar main";
              always = true;
              notification = false;
            }
            {
              command = "pkill picom; picom";
              always = true;
              notification = false;
            }
          ];

          bars = [ ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "1";

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
        };
      };
    };
}
