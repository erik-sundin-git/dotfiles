{ ... }:
{
  flake.modules.homeManager.hyprland =
    {
      lib,
      pkgs,
      waylandScreenshots,
      isLaptop,
      ...
    }:
    {
      home.packages = [
        pkgs.jq
        pkgs.pavucontrol
        pkgs.pulseaudio
        pkgs.swayosd
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
        pkgs.hyprpolkitagent
        pkgs.nerd-fonts.jetbrains-mono
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
