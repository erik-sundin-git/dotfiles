{
  inputs,
  lib,
  config,
  ...
}:
let
  installer = config.flake.installer;
  nixosModules = config.flake.modules.nixos;
  hmModules = config.flake.modules.homeManager;

  # Eval-only: enough for toplevel to evaluate, never built or booted
  testSystem =
    modules:
    (inputs.nixpkgs.lib.nixosSystem {
      modules = modules ++ [
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          systemConstants.system.host = "installer-test";
          system.stateVersion = installer.stateVersion;
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };
          commonConfig.bootEFI = false;
          boot.loader.grub.device = "nodev";
        }
      ];
    }).config.system.build.toplevel;

  defaultStack = lib.head (lib.attrNames (lib.filterAttrs (_: s: s.default) installer.stacks));

  missing =
    lib.filter (n: !(nixosModules ? ${n})) (
      lib.attrNames installer.profiles
      ++ lib.attrNames installer.stacks
      ++ lib.attrNames installer.features
    )
    ++ lib.filter (n: !(hmModules ? ${n})) (lib.attrNames installer.homeModules);
  unregisteredStacks = lib.filter (n: lib.hasSuffix "Stack" n && !(installer.stacks ? ${n})) (
    lib.attrNames nixosModules
  );
in
{
  # install-host offers any profile x stack x feature x homeModule combination,
  # most of which no host uses. `nix flake check --no-build` (and CI)
  # evaluates one system per stack, plus one with every feature and
  # homeModule, so a combination the installer offers can't rot unnoticed.
  # EXWM's system also catches a sway bind without an EXWM translation.
  perSystem =
    { pkgs, system, ... }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") (
        lib.mapAttrs' (
          stack: _:
          lib.nameValuePair "installer-${stack}" (testSystem [
            nixosModules.laptopBaseProfile
            nixosModules.${stack}
          ])
        ) installer.stacks
        // {
          installer-all-extras = testSystem (
            [
              nixosModules.laptopBaseProfile
              nixosModules.${defaultStack}
            ]
            ++ map (n: nixosModules.${n}) (lib.attrNames installer.features)
            ++ [
              {
                home-manager.users.erik.imports = map (n: hmModules.${n}) (lib.attrNames installer.homeModules);
              }
            ]
          );

          installer-names =
            if missing != [ ] then
              throw "flake.installer names modules that don't exist: ${toString missing}"
            else if unregisteredStacks != [ ] then
              throw "Stacks without a flake.installer.stacks entry: ${toString unregisteredStacks}"
            else if lib.length (lib.attrNames (lib.filterAttrs (_: s: s.default) installer.stacks)) != 1 then
              throw "Exactly one flake.installer.stacks entry must set default = true"
            else
              pkgs.emptyFile;
        }
      );
    };
}
