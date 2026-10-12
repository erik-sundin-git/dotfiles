{ inputs, ... }:
{
  flake.modules.nixos.i3 =
    { pkgs, ... }:
    {
      # LightDM runs the Home Manager generated ~/.hm-xsession, which starts
      # i3 and hm-graphical-session.target (polybar, picom, ...).
      services.xserver.desktopManager.session = [
        {
          name = "home-manager";
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
            waitPID=$!
          '';
        }
      ];
      services.displayManager.defaultSession = "home-manager";
      security.pam.services.i3lock = { };
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

      xsession.enable = true;
      xsession.scriptPath = ".hm-xsession";

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
              command = "proton-mail";
              notification = false;
            }
            {
              command = "${importEnv}";
              notification = false;
            }
          ];
        };
      };
    };
}
