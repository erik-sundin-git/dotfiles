{ inputs, ... }:
{
  flake.modules.nixos.xfceStack =
    { ... }:
    {
      imports = [ inputs.self.modules.nixos.xfce ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.xfceStack
      ];
    };

  flake.modules.homeManager.xfceStack =
    { config, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        alacritty
        gtk
      ];

      # xfsettingsd pushes XSETTINGS that override gtk's settings.ini.
      xfconf.settings.xsettings = {
        "Net/ThemeName" = config.gtk.theme.name;
        "Net/IconThemeName" = config.gtk.iconTheme.name;
      };
    };
}
