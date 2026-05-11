{ inputs, ... }:
{
  flake.modules.nixos.hyprlandStack =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
      ];

      programs.hyprland.enable = true;
      programs.hyprland.xwayland.enable = true;

      # Portals for screen sharing, file picker, etc.
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };

  flake.modules.homeManager.hyprlandStack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hyprland
        waybar
        gtk
        dunst
        starship
      ];
    };
}
