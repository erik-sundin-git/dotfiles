{ ... }:
{
  flake.modules.nixos.waylandBase =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };

  # Shared by the sway and Hyprland HM modules. Needs uiHelpers (for
  # waylandScreenshots), which both already import; importing it here too
  # would define its function-valued module args twice.
  flake.modules.homeManager.waylandBase =
    {
      lib,
      pkgs,
      waylandScreenshots,
      isLaptop,
      ...
    }:
    {
      programs.emacs.package = pkgs.emacs-pgtk;
      # Start the daemon after the compositor so it inherits WAYLAND_DISPLAY;
      # child processes it spawns (e.g. mpv from ~/dev/emacs-yt) need it.
      services.emacs.startWithUserSession = "graphical";

      home.packages = [
        pkgs.jq
        pkgs.pavucontrol
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [ pkgs.brightnessctl ];
    };
}
