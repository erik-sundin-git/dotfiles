{ config, inputs, ... }:
{
  flake.modules.homeManager.debianLaptop =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        minimal-config
      ];

      home.packages = with pkgs; [
        nixfmt
      ];
      home.homeDirectory = "/home/erik";
      systemConstants.system.type = "laptop";
      systemConstants.system.host = "nomad";
      systemConstants.latitude = 59.33;
      systemConstants.longitude = 18.07;
    };
}
