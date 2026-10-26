{ ... }:
{
  flake.modules.homeManager.firefox =
    { mozillaShared, ... }:
    {
      programs.firefox = {
        enable = true;

        policies.DontCheckDefaultBrowser = true;

        profiles."default" = {
          # DDG's Swedish results are poor; LibreWolf keeps it.
          search = mozillaShared.search // {
            default = "Startpage";
            privateDefault = "Startpage";
          };
          settings = mozillaShared.settings // {
            "browser.startup.homepage" = "https://www.youtube.com";
          };
          extensions.packages = mozillaShared.extensions;
          userChrome = mozillaShared.userChrome;
        };
      };
    };
}
