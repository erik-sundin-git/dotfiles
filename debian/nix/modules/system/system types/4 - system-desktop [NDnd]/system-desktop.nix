{
  inputs,
  ...
}:
{
  # expansion of cli system for desktop use

  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules.nixos; [
      system-cli
    ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  flake.modules.homeManager.system-desktop = {
    imports = with inputs.self.modules.homeManager; [
      system-cli
    ];
  };
}
