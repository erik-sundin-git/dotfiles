{
  inputs,
  ...
}:
{
  # default settings needed for all homeManagerConfigurations

  flake.modules.homeManager.minimal-config =
    { config, ... }:
    {
      imports = [inputs.self.modules.generic.systemConstants];
      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = "23.05";
      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };
      programs.home-manager.enable = true;
    };
}
