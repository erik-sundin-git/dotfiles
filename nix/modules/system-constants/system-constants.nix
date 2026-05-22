{ inputs, ... }:
{
  flake.modules.generic.systemConstants =
    { lib, pkgs, ... }:
    {
      config._module.args.pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

      options.systemConstants = {
        adminEmail = lib.mkOption {
          type = lib.types.str;
          default = "mail@eriksundin.com";
          description = "Primary email address of the admin user.";
        };
        adminName = lib.mkOption {
          type = lib.types.str;
          default = "Erik Sundin";
          description = "Full name of the admin user.";
        };

        # location for use with services like redshift
        latitude = lib.mkOption {
          type = lib.types.float;
          default = 59.33; # Stockholm
          description = "Geographic latitude of the host, used by redshift.";
        };
        longitude = lib.mkOption {
          type = lib.types.float;
          default = 18.07; # Stockholm
          description = "Geographic longitude of the host, used by redshift.";
        };

        thermalZonePath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Sysfs path to the thermal zone for CPU temperature display in the polybar bar. Set to null to disable.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.path;
          default = "${inputs.self}/Pictures/landscapes/mountain_landscape_1.jpg";
          description = "Path to the desktop wallpaper used by sway/hyprland.";
        };

        keyboard = {
          layout = lib.mkOption {
            type = lib.types.str;
            default = "se";
            description = "X11/Wayland keyboard layout (xkb).";
          };
          options = lib.mkOption {
            type = lib.types.str;
            default = "ctrl:swapcaps";
            description = "X11/Wayland keyboard options (xkb).";
          };
        };

        network = {
          forgeHost = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.224";
            description = "LAN address of the forge desktop, used by the ssh-desktop alias.";
          };
        };

        system = {
          type = lib.mkOption {
            type = lib.types.enum [
              "desktop"
              "laptop"
            ];
            description = "Form factor of the host; controls laptop-specific features like touchpad and brightness keys.";
          };
          host = lib.mkOption {
            type = lib.types.enum [
              "nomad"
              "forge"
              "ether"
              "specter"
            ];
            description = "Canonical name of this host; used to select host-specific shell aliases and config.";
          };
        };
      };
    };
}
