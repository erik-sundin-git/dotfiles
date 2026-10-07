{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { ... }:
      let
        sysConst = {
          type = "laptop";
          host = "nomad";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          commonDesktop
          swayfxStack
          gaming
          pulseaudio
          virtManager
        ];

        systemConstants.system = sysConst;

        services.hardware.bolt.enable = true;

        networking.nat = {
          enable = true;
          externalInterface = "wlp61s0";
          forwardPorts = [
            { destination = "192.168.122.5:8123"; proto = "tcp"; sourcePort = 8123; }
          ];
        };

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            gh
            chromium
          ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
          selectedTheme = "catppuccin";

          wayland.windowManager.sway.config.output = {
            "Dell Inc. DELL U2722D 3JYTCH3" = {
              mode = "2560x1440";
              position = "0,0";
            };
            "eDP-1".position = "2560,0";
          };
        };
      };
  };
}
