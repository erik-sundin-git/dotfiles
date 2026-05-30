{ inputs, ... }:
{
  flake.modules.nixos.xfceStack =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.xfce
        inputs.self.modules.generic.theme
      ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.xfceStack
      ];
    };

  flake.modules.homeManager.xfceStack =
    { ... }:
    {
      imports = [
        inputs.self.modules.homeManager.gtk
      ];
    };
}
