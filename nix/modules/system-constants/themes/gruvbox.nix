{ ... }:

# Gruvbox Dark (medium) — https://github.com/morhetz/gruvbox
# Terminal color mapping follows the official gruvbox palette (neutral normals,
# bright brights); black is lifted to bg1 so it reads as a surface in the UI.
{
  flake.modules.generic.theme =
    { lib, config, ... }:
    {
      config.theme = lib.mkIf (config.selectedTheme == "gruvbox") {
        # Shape/opacity: retro and solid — slight rounding, opaque, small gaps.
        rounding = 4;
        gaps = 4;
        opacity = 1.0;
        blur = false;

        # The neutral blue is too dark to carry text; gruvbox's red is too
        # dark for background-colored text on urgent title bars
        accent = "#83a598"; # brightBlue
        urgentForeground = "#ebdbb2"; # fg1

        background = "#282828"; # bg0
        superDark = "#1d2021"; # bg0_h
        foreground = "#ebdbb2"; # fg1
        cursor = "#ebdbb2"; # fg1
        cursorText = "#282828"; # bg0

        black = "#3c3836"; # bg1
        red = "#cc241d";
        green = "#98971a";
        yellow = "#d79921";
        blue = "#458588";
        magenta = "#b16286";
        cyan = "#689d6a";
        white = "#a89984"; # fg4

        # bright variants
        brightBlack = "#928374"; # gray
        brightRed = "#fb4934";
        brightGreen = "#b8bb26";
        brightYellow = "#fabd2f";
        brightBlue = "#83a598";
        brightMagenta = "#d3869b";
        brightCyan = "#8ec07c";
        brightWhite = "#ebdbb2"; # fg1
      };
    };
}
