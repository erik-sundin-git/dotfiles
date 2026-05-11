{ ... }:
{
  flake.modules.homeManager.polybar =
    { config, pkgs, mkScript, ... }:
    let
      c = config.theme;
      script = pkgs.writeShellScript "polybar-ethernet" ''
        ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')
        if [ -n "$ip" ]; then
          echo "%{F${c.green}}E: $ip%{F-}"
        else
          echo "%{F${c.red}}E: down%{F-}"
        fi
      '';
    in
    {
      services.polybar.settings."module/ethernet" = mkScript { exec = script; };
    };
}
