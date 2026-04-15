{
  inputs,
  self,
  ...
}:
{
  flake.modules.nixos.linux-desktop =
    { config, ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        with inputs.self.factory;
        [
          erik
        ];

      home-manager.users.erik = {
        ###
      };
    };
}
