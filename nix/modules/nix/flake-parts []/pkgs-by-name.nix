{ inputs, withSystem, ... }:
{
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    pkgsDirectory = inputs.packages;
  };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }: { local = config.packages; }
    );
}
