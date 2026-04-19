{
  inputs,
  ...
}:
{
  flake.modules.homeManager.librewolf =
    { pkgs, config, ... }:

    {
      programs.librewolf = {
        enable = true;

        profiles."default".extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
            darkreader
          ];
        };
      };

    };
}
