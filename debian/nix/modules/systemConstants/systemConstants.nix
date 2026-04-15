{ inputs, ... }:
{
  flake.modules.generic.systemConstants =
    { lib, pkgs, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };

      config.systemConstants = {
        adminEmail = "mail@eriksundin.com";
        adminName = "Erik Sundin";
        configDir = inputs.self;
      };
    };
}
