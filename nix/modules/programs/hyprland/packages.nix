{ ... }:
{
  flake.modules.homeManager.hyprland =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.pulseaudio
        pkgs.swayosd
        pkgs.hyprpolkitagent
      ];
    };
}
