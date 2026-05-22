{ ... }:
{
  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      waylandScreenshots,
      ...
    }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      home.packages = [
        pkgs.wofi
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
