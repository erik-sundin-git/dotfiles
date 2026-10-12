{ inputs, ... }:
{
  flake.modules.homeManager.firefox =
    { mozillaShared, ... }:
    {
      imports = [ inputs.self.modules.homeManager.mozillaShared ];

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
