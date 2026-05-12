{
  flake.modules.homeManager.alacritty =
    { config, lib, pkgs, ... }:
    let
      c = config.theme;
      nixGLPkg = config.debianGL.nixGLPackage;
      fontFamily = "AdwaitaMono Nerd Font";
    in
    {
      options.debianGL.nixGLPackage = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
      };

      config.programs.alacritty = {
        enable = true;
        package =
          if nixGLPkg == null then
            pkgs.alacritty
          else
            pkgs.writeShellScriptBin "alacritty" ''
              exec ${lib.getExe nixGLPkg} ${pkgs.alacritty}/bin/alacritty "$@"
            '';
        settings = {
          font = {
            size = 12.0;
            normal = {
              family = fontFamily;
              style = "Regular";
            };
            bold = {
              family = fontFamily;
              style = "Bold";
            };
            italic = {
              family = fontFamily;
              style = "Italic";
            };
            bold_italic = {
              family = fontFamily;
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
            opacity = 0.85;
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
