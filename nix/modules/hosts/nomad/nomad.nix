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
          pulseaudio
          virtManager
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.gh ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
        };
      };
  };
}
