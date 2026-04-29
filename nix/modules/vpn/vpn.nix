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
      home.packages =
        (with pkgs; [
          wireguard-tools
          proton-vpn-cli
        ])
        ++ [
          (pkgs.writeShellApplication {
            name = "vpn-status";
            text = builtins.readFile ./vpn-status.sh;
          })
        ];

      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };
    };
}
