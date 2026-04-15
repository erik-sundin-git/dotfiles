{
  inputs,
  ...
}:
let
  username = "erik";
in
{
  flake.modules.homeManager."${username}" =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-desktop
        hyprland
        hyprland-hyprpaper
        hyprland-idle
        waybar
        browser
        mail
        office
        stylix
      ];
      home.username = "${username}";
      home.packages = with pkgs; [

      ];
    };
}
