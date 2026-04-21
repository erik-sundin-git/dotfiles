{ config, inputs, ... }:
{
  flake.modules.homeManager.debianDesktop =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
      ];

      home.packages = with pkgs; [
        nixfmt
      ];
      home.homeDirectory = "/home/erik";
      systemConstants.system.type = "desktop";
      systemConstants.system.host = "forge";

    };
}
