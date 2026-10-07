{ ... }:

{
  flake.modules.generic.theme =
    { config, lib, ... }:
    {
      options = {
        selectedTheme = lib.mkOption {
          type = lib.types.enum [ "onedark" "catppuccin" ];
          default = "onedark";
          description = "Name of the active theme. Must match a theme file in system-constants/themes/.";
        };

        # `theme` mixes semantic colors (str) with typed style knobs. The
        # freeformType lets each theme file drop in its palette as arbitrary
        # `themeName = "#rrggbb"` pairs without declaring every key here.
        theme = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.attrsOf lib.types.str;
            options = {
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
                type = lib.types.float;
                default = 1.0;
                description = "Window opacity, 0.0–1.0. 1.0 = fully opaque.";
              };
              blur = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable compositor blur behind transparent windows.";
              };
              fontFamily = lib.mkOption {
                type = lib.types.str;
                default = "JetBrainsMono Nerd Font";
                description = "Monospace font used across terminal, bar, launcher, and notifications.";
              };
            };
          };
          default = { };
          description = "Resolved theme: color palette + shape/opacity knobs.";
        };
      };

      config.assertions = [
        {
          assertion = (config.theme.background or "") != "";
          message = "selectedTheme = \"${config.selectedTheme}\" does not match any theme file in system-constants/themes/.";
        }
      ];
    };
}
