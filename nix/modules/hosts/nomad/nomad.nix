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
          hyprlandStack
          virtManager
        ];

        systemConstants.system = sysConst;

        home-manager.backupFileExtension = "backup";
        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            commonHome
            hyprlandStack
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
          ];
        };

        services.xserver.displayManager.lightdm.enable = false;
        services.xserver.displayManager.startx.enable = true;

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      };
  };
}
