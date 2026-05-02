{ inputs, ... }:
{
  flake.modules.nixos.xfceStack =
    { ... }:
    {
      imports = with inputs.self.modules; [
        nixos.xfce
        generic.theme
      ];
      home-manager.users.erik.imports = [
        inputs.self.modules.homeManager.gtk
      ];
    };
}
