{ ... }:
{
  flake.modules.homeManager.polybar =
    { config, lib, pkgs, mkScript, ... }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      c = config.theme;
      script = pkgs.writeShellScript "polybar-wireless" ''
        conn=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}')
        if [ -n "$conn" ]; then
          if [ -f $XDG_RUNTIME_DIR/polybar_wifi_mode ]; then
            iface=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '/wifi$/{print $1; exit}')
            ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{split($2,a,"/"); print a[1]; exit}')
            echo "%{F${c.green}}$conn $ip%{F-}"
          else
            echo "%{F${c.green}}$conn%{F-}"
          fi
        else
          echo "%{F${c.red}}W: down%{F-}"
        fi
      '';
      toggle = "[ -f $XDG_RUNTIME_DIR/polybar_wifi_mode ] && rm $XDG_RUNTIME_DIR/polybar_wifi_mode || touch $XDG_RUNTIME_DIR/polybar_wifi_mode";
    in
    lib.mkIf laptop {
      services.polybar.settings."module/wireless" = mkScript {
        exec = script;
        clickLeft = toggle;
        interval = 1;
      };
    };
}
