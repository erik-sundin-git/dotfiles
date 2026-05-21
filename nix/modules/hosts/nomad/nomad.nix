{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { pkgs, ... }:
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
          virtManager
        ];

        systemConstants.system = sysConst;
        services.tlp.enable = false;

        home-manager.backupFileExtension = "backup";
        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            commonHome
            swayfxStack
            alacritty
            chromium
            vpn
            airstatus
          ];
          systemConstants.system = sysConst;
          systemConstants.latitude = 59.33; # Stockholm
          systemConstants.longitude = 18.07; # Stockholm
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone6/temp";
          services.airstatus.enable = true;
          home.packages = with pkgs; [
            protonmail-desktop
            beeper
            vlc
            zip
            ffmpeg
            yt-dlp
            htop
          ];
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
