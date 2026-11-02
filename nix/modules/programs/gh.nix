{ ... }:
{
  flake.installer.homeModules.gh = {
    label = "GitHub CLI (gh)";
    order = 10;
    profiles = [
      "laptopBaseProfile"
      "desktopBaseProfile"
      "serverProfile"
    ];
  };

  flake.modules.homeManager.gh =
    { ... }:
    {
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };
    };
}
