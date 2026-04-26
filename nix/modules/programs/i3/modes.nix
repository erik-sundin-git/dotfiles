{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  flake.modules.homeManager.i3 = {
    xsession.windowManager.i3.config.modes = {
      launch = {
        "e" = "exec emacs; mode \"default\"";
        "l" = "exec librewolf; mode \"default\"";
        "Escape" = "mode \"default\"";
        "space" = "mode \"default\"";
      };
      resize = {
        "j" = "resize grow height 10 px or 10 ppt";
        "Escape" = "mode \"default\"";
        "h" = "resize shrink width 10 px or 10 ppt";
        "space" = "mode \"default\"";
        "l" = "resize grow width 10 px or 10 ppt";
        "k" = "resize shrink height 10 px or 10 ppt";
      };
    };
  };
}
