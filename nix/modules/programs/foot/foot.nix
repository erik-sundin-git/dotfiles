{ ... }:
{
  # foot, the sway stack's terminal. The server (on sway-session.target via
  # HM's wayland.systemd.target) keeps fonts and the renderer warm, so
  # footclient windows open instantly. All footclient windows live in that one
  # process: swayfxStack keeps earlyoom off it.
  flake.modules.homeManager.foot =
    { config, lib, ... }:
    let
      c = config.theme;
      hex = lib.removePrefix "#";
    in
    {
      programs.foot = {
        enable = true;
        server.enable = true;
        settings = {
          main = {
            font = "${c.fontFamily}:size=12";
            pad = "8x8";
            # foot's own terminfo is missing on most remote hosts (vps)
            term = "xterm-256color";
          };
          scrollback.lines = 10000;
          cursor = {
            style = "block";
            blink = "no";
          };
          colors-dark = {
            alpha = c.opacity;
            background = hex c.background;
            foreground = hex c.foreground;
            cursor = "${hex c.cursorText} ${hex c.cursor}";
            regular0 = hex c.black;
            regular1 = hex c.red;
            regular2 = hex c.green;
            regular3 = hex c.yellow;
            regular4 = hex c.blue;
            regular5 = hex c.magenta;
            regular6 = hex c.cyan;
            regular7 = hex c.white;
            bright0 = hex c.brightBlack;
            bright1 = hex c.brightRed;
            bright2 = hex c.brightGreen;
            bright3 = hex c.brightYellow;
            bright4 = hex c.brightBlue;
            bright5 = hex c.brightMagenta;
            bright6 = hex c.brightCyan;
            bright7 = hex c.brightWhite;
          };
        };
      };
    };
}
