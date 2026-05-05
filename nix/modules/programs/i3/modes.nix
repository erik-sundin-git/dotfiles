{ ... }:
{
  flake.modules.homeManager.i3 =
    { mkModeNotif, ... }:
    let
      exit = {
        "Escape" = "mode \"default\"";
        "space" = "mode \"default\"";
      };
      powerNotif = mkModeNotif {
        summary = "Power";
        body = "h  hibernate\nEsc/Spc  exit";
      };
      powerExit = {
        "Escape" = "exec --no-startup-id ${powerNotif.exit}; mode \"default\"";
        "space" = "exec --no-startup-id ${powerNotif.exit}; mode \"default\"";
      };
    in
    {
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
