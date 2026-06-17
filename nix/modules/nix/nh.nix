{ inputs, ... }:
{
  flake.modules.homeManager.nh =
    { ... }:
    {
      programs.nh = {
        enable = true;
        flake = "${inputs.self}";
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5";
      };
    };
}
