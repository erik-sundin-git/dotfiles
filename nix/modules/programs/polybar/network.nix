{ ... }:
{
  flake.modules.homeManager.polybar =
    {
      config,
      lib,
      mkScript,
      ...
    }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      c = config.theme;
    in
    {
      services.polybar.settings = {
        "module/vpn" = mkScript {
          exec = ''result=$(vpn-status 2>/dev/null); if [ -n "$result" ]; then echo "%{F${c.green}}$result%{F-}"; else echo "%{F${c.red}}VPN%{F-}"; fi'';
        };

        "module/ipv6" = mkScript {
          exec = ''addr=$(ip -6 addr show scope global | awk '/inet6/{print $2; exit}'); if [ -n "$addr" ]; then if [ -f $XDG_RUNTIME_DIR/polybar_ipv6_mode ]; then echo "%{F${c.green}}$addr%{F-}"; else echo "%{F${c.green}}IPV6%{F-}"; fi; else echo "IPV6"; fi'';
          clickLeft = "[ -f $XDG_RUNTIME_DIR/polybar_ipv6_mode ] && rm $XDG_RUNTIME_DIR/polybar_ipv6_mode || touch $XDG_RUNTIME_DIR/polybar_ipv6_mode";
        };

        "module/ethernet" = mkScript {
          exec = ''ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}'); if [ -n "$ip" ]; then echo "%{F${c.green}}E: $ip%{F-}"; else echo "%{F${c.red}}E: down%{F-}"; fi'';
        };
      } // lib.optionalAttrs laptop {
        "module/wireless" = mkScript {
          exec = ''conn=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}'); if [ -n "$conn" ]; then if [ -f $XDG_RUNTIME_DIR/polybar_wifi_mode ]; then iface=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '/wifi$/{print $1; exit}'); ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{split($2,a,"/"); print a[1]; exit}'); echo "%{F${c.green}}$conn $ip%{F-}"; else echo "%{F${c.green}}$conn%{F-}"; fi; else echo "%{F${c.red}}W: down%{F-}"; fi'';
          clickLeft = "[ -f $XDG_RUNTIME_DIR/polybar_wifi_mode ] && rm $XDG_RUNTIME_DIR/polybar_wifi_mode || touch $XDG_RUNTIME_DIR/polybar_wifi_mode";
          interval = 1;
        };
      };
    };
}
