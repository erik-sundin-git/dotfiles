{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = {
    imports =
      with inputs.self.modules.nixos;
      [
        system-minimal
        home-manager
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
      ]);
  };

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}
