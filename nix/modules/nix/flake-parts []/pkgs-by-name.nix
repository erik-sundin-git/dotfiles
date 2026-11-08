{ inputs, lib, ... }:
let
  # nix/packages/<name>/package.nix, each a callPackage-style function
  directory = ../../../packages;
  byName = callPackage: lib.packagesFromDirectoryRecursive { inherit callPackage directory; };
in
{
  # `nix build .#<name>` / `nix run .#update-debs` (and CI) use these
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      _module.args.pkgs = pkgs;
      packages = byName pkgs.callPackage;
    };

  # Hosts get them as pkgs.local.<name>, called with the host's own pkgs, so
  # host overlays and nixpkgs config reach them too (no second nixpkgs)
  flake.overlays.default = final: _prev: { local = byName final.callPackage; };
}
