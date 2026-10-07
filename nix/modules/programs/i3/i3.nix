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
      ...
    }:
    let
      t = config.theme;
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
          bars = [ ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "workspace number 1";

          gaps = {
            inner = t.gaps;
            outer = t.gaps;
          };

          window.border = 2;
          floating.border = 2;

          startup = [
            {
              command = "nitrogen --restore";
              notification = false;
            }
            {
              command = "blueman-applet";
              notification = false;
            }
            {
              command = "dunst";
              notification = false;
            }
            {
              command = "proton-mail";
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
        };
      };
    };
}
