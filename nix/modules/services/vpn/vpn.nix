{ ... }:
{
  flake.modules.homeManager.vpn =
    { pkgs, pkgsUnstable, ... }:
    {
      home.packages =
        (with pkgs; [
          wireguard-tools
        ])
        ++ [
          pkgsUnstable.proton-vpn-cli
        ]
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
