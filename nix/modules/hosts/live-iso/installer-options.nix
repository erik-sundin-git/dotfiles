{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;

  entry =
    extraOptions:
    types.submodule {
      options = {
        label = mkOption { type = types.str; };
        order = mkOption {
          type = types.int;
          default = 50;
          description = "Menu position; lower comes first.";
        };
      }
      // extraOptions;
    };

  forProfiles = mkOption {
    type = types.listOf types.str;
    default = [
      "laptopBaseProfile"
      "desktopBaseProfile"
    ];
    description = "Keys of installer.profiles that offer this entry.";
  };

  # Boards an x86_64 installer has no use for
  armBoards = [
    "bananapi-"
    "beagleboard-"
    "friendlyarm-"
    "fydetab-"
    "hardkernel-odroid-hc4"
    "hardkernel-odroid-m1"
    "kobol-"
    "microchip-"
    "milkv-"
    "mnt-reform-"
    "nxp-"
    "olimex-"
    "pine64-"
    "purism-librem-5"
    "radxa-"
    "raspberry-pi-"
    "rock-"
    "spacemit-"
    "starfive-"
    "ucm-"
  ];
in
{
  # What install-host offers for a new host, read with
  # `nix eval --json .#installer`. Each module registers itself next to its
  # definition (stacks/*.nix, gaming.nix, profiles.nix, ...), the way theme
  # files feed generic.theme, so a new stack or feature shows up in the
  # installer without touching it. installer-check.nix keeps the names honest.
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    installer = mkOption {
      default = { };
      type = types.submodule {
        options = {
          schemaVersion = mkOption {
            type = types.int;
            description = "Bumped whenever install-host must change to read this data.";
          };
          stateVersion = mkOption { type = types.str; };
          profiles = mkOption {
            default = { };
            type = types.attrsOf (entry {
              type = mkOption {
                type = types.enum [
                  "laptop"
                  "desktop"
                  "server"
                ];
              };
              stacks = mkOption {
                type = types.bool;
                default = true;
                description = "Whether the host picks a WM stack (vmProfile brings its own).";
              };
            });
          };
          stacks = mkOption {
            default = { };
            type = types.attrsOf (entry {
              default = mkOption {
                type = types.bool;
                default = false;
              };
              session = mkOption {
                type = types.enum [
                  "wayland"
                  "x11"
                ];
              };
              experimental = mkOption {
                type = types.bool;
                default = false;
                description = "No host runs it; offered last and marked untested.";
              };
            });
          };
          features = mkOption {
            default = { };
            type = types.attrsOf (entry {
              profiles = forProfiles;
            });
          };
          homeModules = mkOption {
            default = { };
            type = types.attrsOf (entry {
              profiles = forProfiles;
            });
          };
          themes = mkOption { type = types.listOf types.str; };
          defaultTheme = mkOption { type = types.str; };
          nixosHardware = mkOption { type = types.listOf types.str; };
        };
      };
    };
  };

  config.flake.installer = {
    schemaVersion = 1;
    stateVersion = inputs.nixpkgs.lib.trivial.release;
    nixosHardware = builtins.filter (
      name: !lib.hasPrefix "common-" name && !lib.any (board: lib.hasPrefix board name) armBoards
    ) (builtins.attrNames inputs.nixos-hardware.nixosModules);
  };
}
