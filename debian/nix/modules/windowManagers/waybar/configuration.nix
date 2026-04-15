{ inputs, ... }:

{
  flake.modules.homeManager.waybar =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        waybar-bar
        waybar-modules
      ];

      programs.waybar.enable = true;
    };
}
