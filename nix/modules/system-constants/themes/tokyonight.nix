{ ... }:

# Tokyo Night (Night) — https://github.com/folke/tokyonight.nvim
# Terminal color mapping follows the official tokyonight alacritty extra; black
# is lifted to terminal_black so it reads as a surface in the UI.
{
  flake.modules.generic.theme =
    { lib, config, ... }:
    {
      config.theme = lib.mkIf (config.selectedTheme == "tokyonight") {
        # Accent: magenta — background, foreground and half the accents are
        # already blue, so blue highlights disappear into the rest.
        accent = "#bb9af7";

        # Shape/opacity: rounded, slightly translucent with blur, roomy gaps.
        rounding = 10;
        gaps = 6;
        opacity = 0.95;
        blur = true;

        background = "#1a1b26"; # bg
        superDark = "#16161e"; # bg_dark
        foreground = "#c0caf5"; # fg
        cursor = "#c0caf5"; # fg
        cursorText = "#1a1b26"; # bg

        black = "#414868"; # terminal_black
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        cyan = "#7dcfff";
        white = "#a9b1d6"; # fg_dark

        # bright variants — same accents as normal, per the official template.
        brightBlack = "#565f89"; # comment
        brightRed = "#f7768e";
        brightGreen = "#9ece6a";
        brightYellow = "#e0af68";
        brightBlue = "#7aa2f7";
        brightMagenta = "#bb9af7";
        brightCyan = "#7dcfff";
        brightWhite = "#c0caf5"; # fg
      };
    };
}
