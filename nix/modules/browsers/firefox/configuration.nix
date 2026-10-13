{ ... }:
{
  flake.modules.homeManager.firefox =
    { mozillaShared, ... }:
    {
      programs.firefox = {
        enable = true;

        policies.DontCheckDefaultBrowser = true;

        profiles."default" = {
          inherit (mozillaShared) search settings;
          extensions.packages = mozillaShared.extensions;
        };
      };
    };
}
