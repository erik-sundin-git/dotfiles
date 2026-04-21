{ config, inputs, ... }:
{
  flake.modules.homeManager.debianLaptop =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
      ];

      nix.package = pkgs.nix;
      home.packages = with pkgs; [
        nixfmt
      ];
      home.homeDirectory = "/home/erik";
      systemConstants.currentSystemType = "laptop";
      systemConstants.latitude = 59.33;
      systemConstants.longitude = 18.07;
    };
}
