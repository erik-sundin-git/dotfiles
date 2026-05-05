{ ... }:
{
  flake.modules.homeManager.nh =
    { ... }:
    {
      programs.nh = {
        enable = true;
        flake = "/home/erik/dotfiles";
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5";
      };
    };
}
