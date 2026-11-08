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
            runtimeInputs = [
              pkgsUnstable.proton-vpn-cli
              pkgs.libnotify
            ];
            # The kill switch and DNS/IPv6 leak protection are proton-vpn-cli
            # settings (NetworkManager connections), not declarative here.
            text = ''
              if protonvpn status 2>/dev/null | grep -q '^Server:'; then
                if protonvpn disconnect; then notify-send -u low VPN disconnected; else notify-send -u critical "VPN disconnect failed"; fi
              else
                if protonvpn connect; then
                  notify-send -u low "VPN connected" "$(protonvpn status 2>/dev/null | grep '^Server:' || true)"
                else
                  notify-send -u critical "VPN connect failed"
                fi
              fi
            '';
          })
        ];

      programs.bash.shellAliases = {
        vpnup = "protonvpn connect";
        vpndown = "protonvpn disconnect";
      };
    };
}
