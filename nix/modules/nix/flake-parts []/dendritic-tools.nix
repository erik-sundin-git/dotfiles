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
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
