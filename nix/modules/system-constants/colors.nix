{ inputs, lib, ... }:
{
  flake.modules.generic.colors =
    { lib, ... }:
    {
      options.colors = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };

      config.colors = {
        red = "#FF0000";
      };
    };
}
