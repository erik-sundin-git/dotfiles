{ ... }:
{
  flake.modules.homeManager.i3 =
    { config, lib, mkModeNotif, ... }:
    let
      modifier = config.xsession.windowManager.i3.config.modifier;
      exit = {
        "Escape" = "mode \"default\"";
        "space" = "mode \"default\"";
      };
      powerNotif = mkModeNotif {
        modeTitle = "Power";
        bindings = [
          { key = "h"; description = "hibernate"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };
      powerExit = {
        "Escape" = "exec --no-startup-id ${powerNotif.exit}; mode \"default\"";
        "space" = "exec --no-startup-id ${powerNotif.exit}; mode \"default\"";
      };
    in
    {
      xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault {
        "${modifier}+i" = "mode \"launch\"";
        "${modifier}+Shift+p" = "exec --no-startup-id ${powerNotif.enter}; mode \"Power\"";
      };

      xsession.windowManager.i3.config.modes = {
        launch = exit // {
          "e" = "exec emacs; mode \"default\"";
          "l" = "exec librewolf; mode \"default\"";
        };
        resize = exit // {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
        };
        Power = powerExit // {
          "h" = "exec --no-startup-id ${powerNotif.exit}; exec systemctl hibernate; mode \"default\"";
        };
      };
    };
}
