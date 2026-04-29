{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;
    in
    {
      home.packages = lib.optionals laptop [ pkgs.acpi ];

      programs.i3blocks = {
        enable = true;
        bars.config =
          {
            vpn = lib.hm.dag.entryAnywhere {
              command = ''result=$(vpn-status 2>/dev/null); if [ -n "$result" ]; then echo "$result"; echo; echo "#00FF00"; else echo "VPN"; echo; echo "#FF0000"; fi'';
              interval = 5;
            };

            ipv6 = lib.hm.dag.entryAfter [ "vpn" ] {
              command = "ip -6 addr show scope global | awk '/inet6/{print $2; exit}'";
              interval = 30;
            };

            ethernet = lib.hm.dag.entryAfter ([ "ipv6" ] ++ lib.optionals laptop [ "wireless" ]) {
              command = ''ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}'); if [ -n "$ip" ]; then echo "E: $ip"; echo; echo "#00FF00"; else echo "E: down"; echo; echo "#FF0000"; fi'';
              interval = 5;
            };

            disk = lib.hm.dag.entryAfter ([ "ethernet" ] ++ lib.optionals laptop [ "battery" ]) {
              command = "df -h / | awk 'NR==2{print $4}'";
              interval = 30;
            };

            memory = lib.hm.dag.entryAfter ([ "disk" ] ++ lib.optionals (thermalPath != null) [ "temperature" ]) {
              command = ''out=$(free -h | awk '/^Mem:/{print $3 " / " $7}'); avail=$(free -b | awk '/^Mem:/{print $7}'); echo "$out"; if [ "$avail" -lt 1073741824 ]; then echo; echo "#FFFF00"; fi'';
              interval = 5;
            };

            time = lib.hm.dag.entryAfter [ "memory" ] {
              command = "date '+%Y-%m-%d %H:%M:%S'";
              interval = 1;
            };
          }
          // lib.optionalAttrs laptop {
            wireless = lib.hm.dag.entryAfter [ "ipv6" ] {
              command = ''conn=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}'); if [ -n "$conn" ]; then iface=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '/wifi$/{print $1; exit}'); ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{gsub(/\/.*/, "", $2); print $2; exit}'); echo "$conn $ip"; echo; echo "#00FF00"; else echo "W: down"; echo; echo "#FF0000"; fi'';
              interval = 5;
            };

            battery = lib.hm.dag.entryAfter [ "ethernet" ] {
              command = ''out=$(acpi -b 2>/dev/null | head -1 | sed 's/Battery [0-9]*: //'); pct=$(echo "$out" | grep -o '[0-9]*%' | tr -d '%'); echo "$out"; if [ -n "$pct" ] && [ "$pct" -lt 30 ]; then echo; echo "#FF0000"; fi'';
              interval = 30;
            };
          }
          // lib.optionalAttrs (thermalPath != null) {
            temperature = lib.hm.dag.entryAfter [ "disk" ] {
              command = ''awk '{printf "%.0f °C", $1/1000}' ${thermalPath}'';
              interval = 5;
            };
          };
      };
    };
}
