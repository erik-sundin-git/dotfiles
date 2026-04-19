{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      programs.i3status = {
        enable = true;
        enableDefault = false;

        general = {
          colors = true;
          interval = 5;
        };

        modules = {
          "ipv6" = {
            position = 1;
          };
          "ethernet _first_" = {
            position = 3;
            settings = {
              format_up = "E: %ip (%speed)";
              format_down = "E: down";
            };
          };
          "disk /" = {
            position = 5;
            settings = {
              format = "%avail";
            };
          };
          "load" = {
            position = 6;
            settings = {
              format = "%1min";
            };
          };
          "memory" = {
            position = 7;
            settings = {
              format = "%used / %available";
              threshold_degraded = "1G";
              format_degraded = "MEMORY < %available";
            };
          };
          "tztime local" = {
            position = 8;
            settings = {
              format = "%Y-%m-%d %H:%M:%S";
            };
          };
        }

        // lib.optionalAttrs (config.systemConstants.currentSystemType == "laptop") {
          "wireless _first_" = {
            position = 2;
            settings = {
              format_up = "W: (%quality at %essid) %ip";
              format_down = "W: down";
            };
          };
          "battery all" = {
            position = 4;
            settings = {
              format = "%status %percentage %remaining";
              low_threshold = 30;
              threshold_type = "percentage";
              color_bad = "#FF0000";
            };
          };
        };
      };
    };
}
