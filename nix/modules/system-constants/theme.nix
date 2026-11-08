{ lib, ... }:

let
  # One theme per file in ./themes, so adding a file is all it takes
  themeNames = map (lib.removeSuffix ".nix") (
    builtins.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir ./themes))
  );
  defaultTheme = "onedark";

  # Every theme defines these. Consumers index them directly, so a missing key
  # would otherwise surface as an obscure "attribute missing" deep in some module.
  paletteKeys = [
    "background"
    "superDark"
    "foreground"
    "cursor"
    "cursorText"
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
    "brightBlack"
    "brightRed"
    "brightGreen"
    "brightYellow"
    "brightBlue"
    "brightMagenta"
    "brightCyan"
    "brightWhite"
  ];
in
{
  flake.installer = {
    themes = themeNames;
    inherit defaultTheme;
  };

  flake.modules.generic.theme =
    { config, lib, ... }:
    let
      missing = builtins.filter (k: (config.theme.${k} or "") == "") paletteKeys;
      # "" is allowed so a missing key reaches the assertion below (which names
      # it) instead of failing as a type error deep in some UI module
      color = lib.types.strMatching "(#[0-9a-fA-F]{6})?";
      fraction = lib.types.numbers.between 0.0 1.0;
    in
    {
      options = {
        selectedTheme = lib.mkOption {
          type = lib.types.enum themeNames;
          default = defaultTheme;
          description = "Name of the active theme: a file name in system-constants/themes/ without .nix.";
        };

        # `theme` mixes semantic colors (str) with typed style knobs. The
        # freeformType lets each theme file drop in its palette as arbitrary
        # `themeName = "#rrggbb"` pairs without declaring every key here.
        theme = lib.mkOption {
          type = lib.types.submodule (
            { config, ... }: {
              freeformType = lib.types.attrsOf color;
              options = {
                accent = lib.mkOption {
                  type = color;
                  default = config.blue or "";
                  defaultText = lib.literalExpression "config.theme.blue";
                  description = "Highlight color for focused borders, active workspaces, selections and rings.";
                };
                urgentForeground = lib.mkOption {
                  type = color;
                  default = config.background or "";
                  defaultText = lib.literalExpression "config.theme.background";
                  description = "Text on urgent (red) title bars. The background color reads best on most reds; themes with a dark red override it.";
                };
                rounding = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  default = 0;
                  description = "Window corner radius in pixels (0 = square).";
                };
                gaps = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  default = 0;
                  description = "Gap between tiled windows in pixels.";
                };
                opacity = lib.mkOption {
                  type = fraction;
                  default = 1.0;
                  description = "Window opacity, 0.0–1.0. 1.0 = fully opaque.";
                };
                blur = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Enable compositor blur behind transparent windows.";
                };
                dimInactive = lib.mkOption {
                  type = fraction;
                  default = if config.opacity < 1.0 then 0.1 else 0.0;
                  defaultText = lib.literalExpression "if opacity < 1.0 then 0.1 else 0.0";
                  description = "How much swayfx dims unfocused windows, 0.0–1.0.";
                };
                fontFamily = lib.mkOption {
                  type = lib.types.str;
                  default = "JetBrainsMono Nerd Font";
                  description = "Monospace font used across terminal, bar, launcher, and notifications.";
                };
              };
            }
          );
          default = { };
          description = "Resolved theme: color palette + shape/opacity knobs.";
        };
      };

      config.assertions = [
        {
          assertion = missing == [ ];
          message = "Theme \"${config.selectedTheme}\" is missing palette keys: ${lib.concatStringsSep ", " missing}";
        }
      ];
    };
}
