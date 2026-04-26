{ inputs, lib, ... }:
{
  flake.modules.generic.systemConstants =
    { lib, pkgs, ... }:
    {
      options.systemConstants = {
        adminEmail = lib.mkOption {
          type = lib.types.str;
          default = "mail@eriksundin.com";
        };
        adminName = lib.mkOption {
          type = lib.types.str;
          default = "Erik Sundin";
        };

        # location for use with services like redshift
        latitude = lib.mkOption {
          type = lib.types.float;
          default = 0.0;
        };
        longitude = lib.mkOption {
          type = lib.types.float;
          default = 0.0;
        };
        system = {
          type = lib.mkOption {
            type = lib.types.enum [
              "desktop"
              "laptop"
            ];
          };
          host = lib.mkOption {
            type = lib.types.enum [
              "nomad"
              "forge"
              "ether"
            ];
          };
        };
      };
    };
}
