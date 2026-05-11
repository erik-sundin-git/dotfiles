{ ... }:
{
  flake.modules.homeManager.polybar =
    { config, pkgs, mkScript, ... }:
    let
      c = config.theme;
      script = pkgs.writeShellScript "polybar-vpn" ''
        result=$(vpn-status 2>/dev/null)
        if [ -n "$result" ]; then
          echo "%{F${c.green}}$result%{F-}"
        else
          echo "%{F${c.red}}VPN%{F-}"
        fi
      '';
    in
    {
      services.polybar.settings."module/vpn" = mkScript { exec = script; };
    };
}
