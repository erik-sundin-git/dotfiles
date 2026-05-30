{ den, inputs, ... }:
{
  den.aspects.forge = {
    nixos =
      { ... }:
      let
        sysConst = {
          type = "desktop";
          host = "forge";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonDesktop
          i3Stack
          pulseaudio
          steam
          virtManager
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.gh ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/hwmon/hwmon2/temp1_input";
        };
      };
  };
}
