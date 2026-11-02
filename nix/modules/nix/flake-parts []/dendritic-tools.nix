{
  inputs,
  ...
}:
{
  # setup of tools for dendritic pattern

  # Simplify Nix Flakes with the module system
  # https://github.com/hercules-ci/flake-parts

  # Import all nix files in a directory tree.
  # https://github.com/vic/import-tree

  imports = [
    inputs.flake-parts.flakeModules.modules
    # Not den's flakeModules.dendritic: that one also sets flake-file options,
    # and flake-file isn't used here (flake.nix is maintained by hand)
    inputs.den.flakeModule
  ];

  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
