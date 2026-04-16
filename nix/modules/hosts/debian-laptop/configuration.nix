{ config, inputs, ... }:
{
  flake.modules.homeManager.debian =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
        emacs
        i3
      ];
      home.username = "erik";
      home.homeDirectory = "/home/erik";

      home.file.".config/nitrogen/nitrogen.cfg".source = "${inputs.self}/nitrogen/nitrogen.cfg";

      home.packages = with pkgs; [
        nixfmt
      ];
    };
}
