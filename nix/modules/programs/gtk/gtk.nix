{ ... }:
{
  flake.modules.homeManager.gtk =
    { pkgs, config, ... }:
    let
      c = config.theme;

      # adw-gtk3 and libadwaita both draw from these named colors, so the same
      # CSS recolors GTK3 and GTK4 apps. The lightdm greeter reuses it too
      # (lightdm.nix reads gtk.gtk3.extraCss).
      paletteCss = ''
        @define-color accent_color ${c.accent};
        @define-color accent_bg_color ${c.accent};
        @define-color accent_fg_color ${c.background};
        @define-color destructive_color ${c.red};
        @define-color destructive_bg_color ${c.red};
        @define-color destructive_fg_color ${c.background};
        @define-color success_color ${c.green};
        @define-color success_bg_color ${c.green};
        @define-color success_fg_color ${c.background};
        @define-color warning_color ${c.yellow};
        @define-color warning_bg_color ${c.yellow};
        @define-color warning_fg_color ${c.background};
        @define-color error_color ${c.red};
        @define-color error_bg_color ${c.red};
        @define-color error_fg_color ${c.background};

        @define-color window_bg_color ${c.background};
        @define-color window_fg_color ${c.foreground};
        @define-color view_bg_color ${c.superDark};
        @define-color view_fg_color ${c.foreground};
        @define-color headerbar_bg_color ${c.black};
        @define-color headerbar_fg_color ${c.foreground};
        @define-color headerbar_backdrop_color ${c.background};
        @define-color sidebar_bg_color ${c.superDark};
        @define-color sidebar_fg_color ${c.foreground};
        @define-color sidebar_backdrop_color ${c.superDark};
        @define-color secondary_sidebar_bg_color ${c.superDark};
        @define-color secondary_sidebar_fg_color ${c.foreground};
        @define-color popover_bg_color ${c.background};
        @define-color popover_fg_color ${c.foreground};
        @define-color dialog_bg_color ${c.background};
        @define-color dialog_fg_color ${c.foreground};
        @define-color card_fg_color ${c.foreground};
      '';
    in
    {
      gtk = {
        enable = true;
        colorScheme = "dark";
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        cursorTheme = {
          name = "Adwaita";
        };
        font = {
          name = "Sans";
          size = 10;
        };
        # libadwaita ignores themes; it only takes the CSS below.
        gtk4.theme = null;
        gtk3.extraCss = paletteCss;
        gtk4.extraCss = paletteCss;
      };

      # libadwaita and the portal read the dark preference from here.
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
}
