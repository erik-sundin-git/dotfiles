{ ... }:
{
  flake.modules.homeManager.desktopApps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qbittorrent
        ffmpeg
        yt-dlp
        local.irealpro
      ];
    };
}
