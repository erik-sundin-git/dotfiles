{
  flake.modules.homeManager.alacritty =
    { config, ... }:
    let
      c = config.colors;
    in
    {
      programs.alacritty = {
        enable = true;
        settings = {
          font = {
            size = 12.0;
            normal = {
              family = "AdwaitaMono Nerd Font";
              style = "Regular";
            };
            bold = {
              family = "AdwaitaMono Nerd Font";
              style = "Bold";
            };
            italic = {
              family = "AdwaitaMono Nerd Font";
              style = "Italic";
            };
            bold_italic = {
              family = "AdwaitaMono Nerd Font";
              style = "Bold Italic";
            };
          };

          colors = {
            primary = {
              background = c.background;
              foreground = c.foreground;
            };
            cursor = {
              text = c.cursorText;
              cursor = c.cursor;
            };
            normal = {
              black = c.black;
              red = c.red;
              green = c.green;
              yellow = c.yellow;
              blue = c.blue;
              magenta = c.magenta;
              cyan = c.cyan;
              white = c.white;
            };
            bright = {
              black = c.brightBlack;
              red = c.brightRed;
              green = c.brightGreen;
              yellow = c.brightYellow;
              blue = c.brightBlue;
              magenta = c.brightMagenta;
              cyan = c.brightCyan;
              white = c.brightWhite;
            };
          };

          window = {
            padding = {
              x = 8;
              y = 8;
            };
            decorations = "full";
          };

          cursor = {
            style = {
              shape = "Block";
              blinking = "Off";
            };
          };

          scrolling = {
            history = 10000;
          };
        };
      };
    };
}
