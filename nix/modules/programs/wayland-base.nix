{ ... }:
{
  flake.modules.nixos.waylandBase =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };

  flake.modules.homeManager.waylandBase =
    { pkgs, ... }:
    {
      programs.emacs.package = pkgs.emacs-pgtk;
    };
}
