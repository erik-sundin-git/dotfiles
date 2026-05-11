{ ... }:
{
  flake.modules.homeManager.polybar =
    { config, pkgs, mkScript, ... }:
    let
      c = config.theme;
      script = pkgs.writeShellScript "polybar-ipv6" ''
        addr=$(ip -6 addr show scope global | awk '/inet6/{print $2; exit}')
        if [ -n "$addr" ]; then
          if [ -f $XDG_RUNTIME_DIR/polybar_ipv6_mode ]; then
            echo "%{F${c.green}}$addr%{F-}"
          else
            echo "%{F${c.green}}IPV6%{F-}"
          fi
        else
          echo "IPV6"
        fi
      '';
      toggle = "[ -f $XDG_RUNTIME_DIR/polybar_ipv6_mode ] && rm $XDG_RUNTIME_DIR/polybar_ipv6_mode || touch $XDG_RUNTIME_DIR/polybar_ipv6_mode";
    in
    {
      services.polybar.settings."module/ipv6" = mkScript {
        exec = script;
        clickLeft = toggle;
      };
    };
}
