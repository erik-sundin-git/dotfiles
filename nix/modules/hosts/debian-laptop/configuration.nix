{ config, inputs, ... }:
{
  flake.modules.homeManager.debian =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
      ];
      home.username = "erik";
      home.homeDirectory = "/home/erik";

      home.packages = with pkgs; [

      ];
    };
}
