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

        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
          dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
          localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        };
        programs.steam.gamescopeSession.enable = true;

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.gh ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
        };
      };
  };
}
