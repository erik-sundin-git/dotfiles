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
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone6/temp";
          services.airstatus.enable = true;
          programs.git.extraConfig."credential \"https://github.com\"".helper = "!/usr/bin/env gh auth git-credential";
          home.packages = with pkgs; [
            gh
            qbittorrent
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
