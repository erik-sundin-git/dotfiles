{ inputs, withSystem, ... }:
{
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

  perSystem = _: {
    pkgsDirectory = inputs.packages;
  };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }: { local = config.packages; }
    );
}
