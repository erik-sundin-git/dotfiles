{ ... }:
{
  flake.modules.homeManager.gtk =
    { pkgs, config, ... }:
    let
      c = config.theme;
      accent = c.blue;
    in
    {
      gtk = {
        enable = true;
        theme = {
          name = "Arc-Dark";
          package = pkgs.arc-theme;
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
        gtk4.theme = null;
        gtk3.extraCss = ''
          @define-color theme_selected_bg_color ${accent};
          @define-color theme_selected_fg_color ${c.black};
          @define-color theme_unfocused_selected_bg_color ${c.brightBlack};
          @define-color accent_color ${accent};
          @define-color accent_bg_color ${accent};
          @define-color accent_fg_color ${c.black};
        '';
      };
    };
}
