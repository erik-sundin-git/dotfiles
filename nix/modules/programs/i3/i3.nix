{ inputs, ... }:
{
  flake.modules.nixos.i3 =
    { ... }:
    {
      services.xserver.displayManager.lightdm.enable = false;
      services.xserver.displayManager.startx.enable = true;
    };

  flake.modules.homeManager.i3 =
    {
      config,
      pkgs,
      mkColors,
      ...
    }:
    let
      c = config.theme;
      importEnv = pkgs.writeShellScript "i3-import-env" ''
        systemctl --user import-environment \
          DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS
        systemctl --user restart \
          xdg-desktop-portal-gtk \
          xdg-desktop-portal
      '';
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
              command = "${importEnv}";
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
