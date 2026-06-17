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
          (pkgs.writeShellApplication {
            name = "vpn-toggle";
            text = builtins.readFile ./vpn-toggle.sh;
          })
        ];

      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };

      programs.bash.shellAliases = {
        vpnup = "protonvpn connect";
        vpndown = "protonvpn disconnect";
      };
    };
}
