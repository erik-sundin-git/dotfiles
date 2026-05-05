{ ... }:
{
  flake.modules.homeManager.dunst =
    { config, ... }:
    let
      c = config.theme;
    in
    {
      services.dunst = {
        enable = true;
        settings = {
          global = {
            frame_color = c.blue;
            separator_color = "frame";
            font = "Monospace 10";
            corner_radius = 4;
            frame_width = 2;
          };
          urgency_low = {
            background = c.black;
            foreground = c.brightBlack;
            frame_color = c.brightBlack;
            timeout = 5;
          };
          urgency_normal = {
            background = c.black;
            foreground = c.foreground;
            frame_color = c.blue;
            timeout = 10;
          };
          urgency_critical = {
            background = c.black;
            foreground = c.red;
            frame_color = c.red;
            timeout = 0;
          };
        };
      };
    };
}
