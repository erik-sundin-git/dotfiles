{
  inputs,
  ...
}:
{
  flake.modules.homeManager.librewolf =
    { pkgs, config, ... }:

    {
      home.sessionVariables.MOZ_USE_XINPUT2 = "1";

      home.file.".librewolf/librewolf.overrides.cfg".text = ''
        lockPref("browser.theme.content-theme", 0);
        lockPref("browser.theme.toolbar-theme", 0);
      '';

      programs.librewolf = {
        enable = true;

        profiles."default".settings = {
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "browser.uidensity" = 1;
          "extensions.autoDisableScopes" = 0;
        };

        profiles."default".extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
          sponsorblock
          consent-o-matic
          vimium
        ];
      };

    };
}
