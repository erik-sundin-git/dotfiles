{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.vpn =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      home.packages = [
        wireguard-tools
        protonvpn-gui
      ];

    };
}
