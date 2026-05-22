{ ... }:
{
  flake.modules.homeManager.swayfx =
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
        pkgs.swayosd
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
        pkgs.nerd-fonts.jetbrains-mono
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
