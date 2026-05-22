{ inputs, ... }:
{
  flake.modules.nixos.xfceStack =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.xfce
        inputs.self.modules.generic.theme
      ];
      home-manager.users.erik.imports = [
        inputs.self.modules.homeManager.gtk
      ];
    };
}
