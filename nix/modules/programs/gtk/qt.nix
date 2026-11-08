{ ... }:
{
  # Qt apps (qbittorrent, vlc, protonup-qt): Fusion with a palette built from
  # the theme, via qt5ct/qt6ct. Part of `gtk` so every stack that themes GTK
  # themes Qt too.
  flake.modules.homeManager.gtk =
    { pkgs, config, ... }:
    let
      c = config.theme;

      # One color per QPalette::ColorRole, in enum order: WindowText, Button,
      # Light, Midlight, Dark, Mid, Text, BrightText, ButtonText, Base, Window,
      # Shadow, Highlight, HighlightedText, Link, LinkVisited, AlternateBase,
      # NoRole, ToolTipBase, ToolTipText, PlaceholderText.
      roles =
        { text, accent }:
        builtins.concatStringsSep ", " [
          text
          c.black
          c.brightBlack
          c.black
          c.superDark
          c.black
          text
          c.brightWhite
          text
          c.superDark
          c.background
          c.superDark
          accent
          c.background
          c.accent
          c.brightMagenta
          c.background
          c.background
          c.black
          c.foreground
          c.brightBlack
        ];

      colorScheme = pkgs.writeText "qtct-${config.selectedTheme}.conf" ''
        [ColorScheme]
        active_colors=${
          roles {
            text = c.foreground;
            accent = c.accent;
          }
        }
        inactive_colors=${
          roles {
            text = c.foreground;
            accent = c.accent;
          }
        }
        disabled_colors=${
          roles {
            text = c.brightBlack;
            accent = c.black;
          }
        }
      '';

      qtctSettings.Appearance = {
        style = "Fusion";
        custom_palette = true;
        color_scheme_path = "${colorScheme}";
        icon_theme = config.gtk.iconTheme.name;
        standard_dialogs = "default";
      };
    in
    {
      qt = {
        enable = true;
        platformTheme.name = "qtct";
        qt5ctSettings = qtctSettings;
        qt6ctSettings = qtctSettings;
      };
    };
}
