{ ... }:
{
  flake.modules.homeManager.nh =
    { config, ... }:
    {
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/dotfiles";
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5";
      };
    };
}
