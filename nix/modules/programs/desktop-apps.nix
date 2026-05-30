{ ... }:
{
  flake.modules.homeManager.desktopApps =
    { pkgs, pkgsUnstable, ... }:
    {
      home.packages = with pkgs; [
        freetube
        qbittorrent
        pkgsUnstable.protonmail-desktop
        pkgsUnstable.multiviewer-for-f1
        beeper
        vlc
        zip
        ffmpeg
        yt-dlp
        htop
      ];
    };
}
