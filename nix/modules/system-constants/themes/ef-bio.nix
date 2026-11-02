{ ... }:

# ef-bio — the Emacs theme from ef-themes (post-init.el loads it), so the
# desktop matches Emacs. Values are the theme's palette as Emacs resolves it
# (`modus-themes-get-color-value`); the names in comments are its palette keys.
# Terminal colors follow ef-bio's own bg-term-* mapping, except black, which is
# lifted to bg-alt so it reads as a surface in the UI (term black is bg-main).
{
  flake.modules.generic.theme =
    { lib, config, ... }:
    {
      config.theme = lib.mkIf (config.selectedTheme == "ef-bio") {
        # Accent: ef-bio's signature green (accent-0)
        accent = "#00c089";

        # Shape/opacity: flat like Emacs — square, opaque, no gaps.
        rounding = 0;
        gaps = 0;
        opacity = 1.0;
        blur = false;

        background = "#111111"; # bg-main
        superDark = "#111111"; # bg-main
        foreground = "#cfdfd5"; # fg-main
        cursor = "#35f038"; # cursor
        cursorText = "#111111"; # bg-main

        black = "#303230"; # bg-alt
        red = "#ef6560";
        green = "#3fb83f";
        yellow = "#d4aa02";
        blue = "#37aff6";
        magenta = "#d38faf";
        cyan = "#6fc5ef";
        white = "#808f80"; # fg-dim

        brightBlack = "#505250"; # bg-active
        brightRed = "#f47360"; # red-warmer
        brightGreen = "#00c089"; # green-cooler
        brightYellow = "#e09a0f"; # yellow-warmer
        brightBlue = "#78afff"; # blue-warmer
        brightMagenta = "#af9fff"; # magenta-cooler
        brightCyan = "#5dc0aa"; # cyan-cooler
        brightWhite = "#cfdfd5"; # fg-main
      };
    };
}
