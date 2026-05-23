{ ... }:
{
  flake.modules.homeManager.swayfx =
    { config, mkColors, ... }:
    let
      c = config.theme;
    in
    {
      wayland.windowManager.sway.config.colors = {
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
}
