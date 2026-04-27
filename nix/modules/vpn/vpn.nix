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
      home.packages = with pkgs; [
        wireguard-tools
        proton-vpn
      ];

    };
}
