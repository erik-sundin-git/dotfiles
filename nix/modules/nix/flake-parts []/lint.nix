{ ... }:
{
  # Unused bindings in the modules. A build check: `nix flake check --no-build`
  # skips it, so CI builds it explicitly. (No nixfmt check: the keybinding
  # tables are aligned by hand on purpose.)
  perSystem =
    { pkgs, ... }:
    {
      checks.deadnix = pkgs.runCommand "deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
        deadnix --fail ${../..}
        touch $out
      '';
    };
}
