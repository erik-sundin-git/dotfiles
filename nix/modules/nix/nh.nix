{ ... }:
{
  flake.modules.homeManager.nh =
    { ... }:
    {
      programs.nh = {
        enable = true;
        flake = "/home/erik/dotfiles";
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5"; # keep last 7 days and 5 generations
      };
    };
}
