{ den, inputs, ... }:
{
  den.aspects.wisp = {
    nixos =
      { ... }:
      let
        sysConst = {
          type = "laptop";
          host = "wisp";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonDesktop
          swayfxStack
          gaming
          geforcenow
          pulseaudio
          virtManager
        ];

        systemConstants.system = sysConst;

        services.hardware.bolt.enable = true;

        home-manager.users.erik =
          { pkgs, ... }:
          {
            imports = with inputs.self.modules.homeManager; [
              gh
              chromium
              geforcenow
            ];
            home.packages = [ pkgs.local.curseforge ];
            systemConstants.system = sysConst;
            systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone6/temp";
          };
      };
  };
}
