{ ... }:
{
  flake.modules.homeManager.firefox =
    { mozillaShared, ... }:
    {
      programs.firefox = {
        enable = true;

        policies.DontCheckDefaultBrowser = true;

        profiles."default" = {
          inherit (mozillaShared) search;
          settings = mozillaShared.settings // {
            "browser.startup.homepage" = "https://www.youtube.com";
          };
          extensions.packages = mozillaShared.extensions;
          userChrome = mozillaShared.userChrome;
        };
      };
    };
}
