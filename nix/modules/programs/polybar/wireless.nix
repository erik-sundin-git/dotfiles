{ ... }:
{
  flake.modules.homeManager.polybar =
    {
      config,
      lib,
      pkgs,
      mkScript,
      isLaptop,
      ...
    }:
    let
      c = config.theme;
      script = lib.getExe (
        pkgs.writeShellApplication {
          name = "polybar-wireless";
          runtimeInputs = [
            pkgs.networkmanager
            pkgs.iproute2
            pkgs.gawk
          ];
          # Probes may fail (no route, no wifi); never abort before printing a status.
          bashOptions = [ ];
          text = ''
            conn=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}')
            if [ -n "$conn" ]; then
              if [ -f "$XDG_RUNTIME_DIR/polybar_wifi_mode" ]; then
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
        }
      );
      toggle = ''[ -f "$XDG_RUNTIME_DIR/polybar_wifi_mode" ] && rm "$XDG_RUNTIME_DIR/polybar_wifi_mode" || touch "$XDG_RUNTIME_DIR/polybar_wifi_mode"'';
    in
    lib.mkIf isLaptop {
      services.polybar.settings."module/wireless" = mkScript {
        exec = script;
        clickLeft = toggle;
        interval = 5;
      };
    };
}
