{ inputs, ... }:
{
  flake.modules.homeManager.debian-laptop =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-default
        waybar
      ];
      home.username = "erik";
      home.packages = with pkgs; [

      ];
    };
}
