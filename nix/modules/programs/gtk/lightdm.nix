{ ... }:
{
  # The LightDM greeter runs before any user session, so it can't read erik's
  # GTK config. Take erik's theme instead: adw-gtk3-dark with the palette CSS
  # from homeManager.gtk baked into a copy of the theme.
  flake.modules.nixos.commonDesktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hm = config.home-manager.users.erik;

      greeterTheme = pkgs.runCommand "adw-gtk3-themed" { } ''
        mkdir -p $out/share/themes
        cp -r --no-preserve=mode ${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark $out/share/themes/adw-gtk3-themed
        cat >> $out/share/themes/adw-gtk3-themed/gtk-3.0/gtk.css <<'EOF'
        ${hm.gtk.gtk3.extraCss}
        EOF
      '';
    in
    {
      services.xserver.displayManager.lightdm = {
        background = hm.systemConstants.wallpaper;
        greeters.gtk = {
          theme = {
            name = "adw-gtk3-themed";
            package = greeterTheme;
          };
          iconTheme = {
            inherit (hm.gtk.iconTheme) name package;
          };
          cursorTheme.name = hm.gtk.cursorTheme.name;
        };
      };
    };
}
