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

  # Wayland pieces for the sway HM module. Needs uiHelpers (for
  # waylandScreenshots), which swayfx already imports; importing it here too
  # would define its function-valued module args twice.
  flake.modules.homeManager.waylandBase =
    {
      config,
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
      # "graphical" alone binds it to graphical-session.target, which comes
      # up before sway exports its environment (see CLAUDE.md), so bind it to
      # the compositor's own target.
      services.emacs.startWithUserSession = "graphical";
      systemd.user.services.emacs = {
        Unit.After = lib.mkForce [ config.wayland.systemd.target ];
        Unit.PartOf = lib.mkForce [ config.wayland.systemd.target ];
        Install.WantedBy = lib.mkForce [ config.wayland.systemd.target ];
      };

      home.packages = [
        pkgs.jq
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [ pkgs.brightnessctl ];
    };
}
