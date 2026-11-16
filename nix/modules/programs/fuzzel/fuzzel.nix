{ ... }:
{
  # fuzzel, the sway stack's launcher and dmenu (app launcher, sway-help, the
  # claude launchers). Its layer is "launcher", which swayfx blurs.
  flake.modules.homeManager.fuzzel =
    { config, lib, ... }:
    let
      c = config.theme;
      # fuzzel colors are rrggbbaa
      rgba = color: alpha: "${lib.removePrefix "#" color}${alpha}";
    in
    {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            font = "${c.fontFamily}:size=11";
            # For Terminal=true desktop entries; plain foot, so it works
            # without the foot server
            terminal = "foot";
            width = 50;
            lines = 12;
            horizontal-pad = 12;
            vertical-pad = 8;
            inner-pad = 6;
          }
          // lib.optionalAttrs (config.gtk.iconTheme != null) {
            icon-theme = config.gtk.iconTheme.name;
          };
          border = {
            width = 1;
            radius = c.rounding;
          };
          colors = {
            background = rgba c.superDark (if c.blur then "d9" else "ff");
            text = rgba c.foreground "ff";
            prompt = rgba c.foreground "ff";
            input = rgba c.foreground "ff";
            match = rgba c.accent "ff";
            selection = rgba c.accent "ff";
            selection-text = rgba c.background "ff";
            selection-match = rgba c.background "ff";
            border = rgba c.accent "ff";
          };
        };
      };
    };
}
