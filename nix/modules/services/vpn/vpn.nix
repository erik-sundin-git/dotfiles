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
            runtimeInputs = [ pkgsUnstable.proton-vpn-cli ];
            text = ''
              protonvpn status 2>/dev/null | grep '^Server:' | sed 's/Server: \(\S*\).*/VPN: \1/'
            '';
          })
          (pkgs.writeShellApplication {
            name = "vpn-toggle";
            runtimeInputs = [ pkgsUnstable.proton-vpn-cli ];
            text = ''
              if protonvpn status 2>/dev/null | grep -q '^Server:'; then
                protonvpn disconnect
              else
                protonvpn connect
              fi
            '';
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
