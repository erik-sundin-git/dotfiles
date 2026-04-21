{ config, inputs, ... }:
{
  flake.modules.homeManager.forge =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
        i3
      ];
      nix.package = pkgs.nix;
      home.packages = with pkgs; [
        nixfmt
      ];
      home.homeDirectory = "/home/erik";
      systemConstants.system.type = "desktop";
      systemConstants.system.host = "forge";

    };
}
