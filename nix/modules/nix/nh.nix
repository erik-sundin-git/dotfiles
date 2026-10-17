{ ... }:
{
  # System side owns cleanup: it runs `nh clean all` as root, which also prunes
  # system generations (the HM-side clean only touched the user profile).
  flake.modules.nixos.nh =
    { ... }:
    {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5";
      };
    };

  flake.modules.homeManager.nh =
    { config, ... }:
    {
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/dotfiles";
      };
    };
}
