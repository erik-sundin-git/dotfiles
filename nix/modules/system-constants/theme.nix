{ ... }:

{
  flake.modules.generic.theme =
    { config, lib, ... }:
    {
      options = {
        selectedTheme = lib.mkOption {
          type = lib.types.str;
          default = "onedark";
          description = "Name of the active theme. Must match a theme file in system-constants/themes/.";
        };

        theme = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Resolved color palette for the selected theme.";
        };
      };

      config.assertions = [
        {
          assertion = config.theme != { };
          message = "selectedTheme = \"${config.selectedTheme}\" does not match any theme file in system-constants/themes/.";
        }
      ];
    };
}
