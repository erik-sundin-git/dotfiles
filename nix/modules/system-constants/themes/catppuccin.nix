{ ... }:

# Catppuccin Mocha — https://catppuccin.com/palette/
# Terminal color mapping follows the official catppuccin/alacritty template.
{
  flake.modules.generic.theme =
    { lib, config, ... }:
    {
      config.theme = lib.mkIf (config.selectedTheme == "catppuccin") {
        # Shape/opacity: rounded, fully opaque, small breathing room between windows.
        rounding = 8;
        gaps = 4;
        opacity = 1.0;
        blur = false;

        background = "#1e1e2e"; # base
        superDark = "#11111b"; # crust
        foreground = "#cdd6f4"; # text
        cursor = "#f5e0dc"; # rosewater
        cursorText = "#1e1e2e"; # base

        black = "#45475a"; # surface1
        red = "#f38ba8"; # red
        green = "#a6e3a1"; # green
        yellow = "#f9e2af"; # yellow
        blue = "#89b4fa"; # blue
        magenta = "#f5c2e7"; # pink
        cyan = "#94e2d5"; # teal
        white = "#bac2de"; # subtext1

        # bright variants — mostly the same as normal per catppuccin's terminal
        # template, with tweaks for black/white to give visible contrast.
        brightBlack = "#585b70"; # surface2
        brightRed = "#f38ba8";
        brightGreen = "#a6e3a1";
        brightYellow = "#f9e2af";
        brightBlue = "#89b4fa";
        brightMagenta = "#f5c2e7";
        brightCyan = "#94e2d5";
        brightWhite = "#a6adc8"; # subtext0
      };
    };
}
