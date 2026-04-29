{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.polybar =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      laptop = config.systemConstants.system.type == "laptop";
      thermalPath = config.systemConstants.thermalZonePath;
      c = config.colors;

      rightModules = lib.concatStringsSep " " (
        [
          "vpn"
          "ipv6"
        ]
        ++ lib.optionals laptop [ "wireless" ]
        ++ [ "ethernet" ]
        ++ lib.optionals laptop [ "battery" ]
        ++ [ "disk" ]
        ++ lib.optionals (thermalPath != null) [ "temperature" ]
        ++ [
          "memory"
          "date"
        ]
      );
    in
    {
      services.polybar = {
        enable = true;

        package = pkgs.polybarFull.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace lib/i3ipcpp/CMakeLists.txt \
              --replace-fail '-std=c++11' '-std=c++17'
          '';
        });

        script = "polybar main &";

        settings = {
          "bar/main" = {
            bottom = true;
            width = "100%";
            height = 22;
            background = c.background;
            foreground = c.foreground;
            font-0 = "monospace:size=12;3";
            modules-left = "i3 tray";
            modules-right = rightModules;
            padding-right = 1;
            module-margin = 1;
            separator = "|";
            separator-foreground = c.brightBlack;
          };

          "module/tray" = {
            type = "internal/tray";
          };

          "module/i3" = {
            type = "internal/i3";
            label-focused = "%index%";
            label-focused-background = c.blue;
            label-focused-foreground = c.black;
            label-focused-padding = 1;
            label-unfocused = "%index%";
            label-unfocused-foreground = c.brightBlack;
            label-unfocused-padding = 1;
            label-urgent = "%index%";
            label-urgent-foreground = c.red;
            label-urgent-padding = 1;
            label-visible = "%index%";
            label-visible-padding = 1;
            label-mode = " %mode% ";
            label-mode-foreground = c.black;
            label-mode-background = c.yellow;
          };

          "module/vpn" = {
            type = "custom/script";
            exec = ''result=$(vpn-status 2>/dev/null); if [ -n "$result" ]; then echo "%{F${c.green}}$result%{F-}"; else echo "%{F${c.red}}VPN%{F-}"; fi'';
            interval = 5;
          };

          "module/ipv6" = {
            type = "custom/script";
            exec = "ip -6 addr show scope global | awk '/inet6/{print $2; exit}'";
            interval = 30;
          };

          "module/ethernet" = {
            type = "custom/script";
            exec = ''ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}'); if [ -n "$ip" ]; then echo "%{F${c.green}}E: $ip%{F-}"; else echo "%{F${c.red}}E: down%{F-}"; fi'';
            interval = 5;
          };

          "module/disk" = {
            type = "internal/fs";
            mount-0 = "/";
            interval = 30;
            label-mounted = "DSK %free%";
          };

          "module/memory" = {
            type = "internal/memory";
            interval = 5;
            warn-percentage = 90;
            label = "RAM %used%";
            label-warn = "RAM %used%";
            label-warn-foreground = c.yellow;
          };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            date = "%Y-%m-%d";
            time = "%H:%M:%S";
            label = "%date% %time%";
          };
        }
        // lib.optionalAttrs laptop {
          "module/wireless" = {
            type = "custom/script";
            exec = ''conn=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}'); if [ -n "$conn" ]; then if [ -f /tmp/polybar_wifi_mode ]; then iface=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '/wifi$/{print $1; exit}'); ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{split($2,a,"/"); print a[1]; exit}'); echo "%{F${c.green}}$conn $ip%{F-}"; else echo "%{F${c.green}}$conn%{F-}"; fi; else echo "%{F${c.red}}W: down%{F-}"; fi'';
            click-left = "[ -f /tmp/polybar_wifi_mode ] && rm /tmp/polybar_wifi_mode || touch /tmp/polybar_wifi_mode";
            interval = 1;
          };

          "module/battery" = {
            type = "internal/battery";
            battery = "BAT0";
            adapter = "AC";
            full-at = 98;
            low-at = 30;
            interval = 30;
            label-charging = " %percentage%%";
            label-discharging = "BAT %percentage%%";
            label-full = "BAT full";
            label-low = "BAT %percentage%%";
            label-low-foreground = c.red;
          };
        }
        // lib.optionalAttrs (thermalPath != null) {
          "module/temperature" = {
            type = "custom/script";
            exec = ''awk '{printf "%.0f °C", $1/1000}' ${thermalPath}'';
            interval = 5;
          };
        };
      };
    };
}
