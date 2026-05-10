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
      launchNotif = mkModeNotif {
        modeTitle = "Launch";
        bindings = [
          { key = "e"; description = "emacs"; }
          { key = "l"; description = "librewolf"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };
      launchExit = {
        "Escape" = "exec --no-startup-id ${launchNotif.exit}; mode \"default\"";
        "space" = "exec --no-startup-id ${launchNotif.exit}; mode \"default\"";
      };
      powerNotif = mkModeNotif {
        modeTitle = "Power";
        bindings = [
          { key = "h"; description = "hibernate"; }
          { key = "r"; description = "reboot"; }
          { key = "s"; description = "shutdown"; }
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
        "${modifier}+i" = "exec --no-startup-id ${launchNotif.enter}; mode \"launch\"";
        "${modifier}+Shift+p" = "exec --no-startup-id ${powerNotif.enter}; mode \"Power\"";
      };

      xsession.windowManager.i3.config.modes = {
        launch = launchExit // {
          "e" = "exec --no-startup-id ${launchNotif.exit}; exec emacs; mode \"default\"";
          "l" = "exec --no-startup-id ${launchNotif.exit}; exec librewolf; mode \"default\"";
        };
        resize = exit // {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
        };
        Power = powerExit // {
          "h" = "exec --no-startup-id ${powerNotif.exit}; exec systemctl hibernate; mode \"default\"";
          "r" = "exec --no-startup-id ${powerNotif.exit}; exec systemctl reboot; mode \"default\"";
          "s" = "exec --no-startup-id ${powerNotif.exit}; exec systemctl poweroff; mode \"default\"";
        };
      };
    };
}
