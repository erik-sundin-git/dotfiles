{ inputs, lib, ... }:

let
  themes = {
    onedark = import ./themes/onedark.nix;
  };
in

{
  flake.lib.themes = themes;

  flake.modules.generic.theme =
    { lib, ... }:
    {
      options.theme = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = themes.onedark;
        description = "Active color theme palette. Switch per-host via inputs.self.lib.themes.<name>.";
      };
    };
}
