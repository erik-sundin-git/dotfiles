{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  flake.modules.homeManager.firefox =
    let
      addons = inputs.nur.legacyPackages."x86_64-linux".repos.rycee.firefox-addons;
    in
    {
      inputs,
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.firefox = {
        enable = true;
        profiles.default = {
          isDefault = true;
          extensions = {
            packages = with addons; [
              bitwarden
              ublock-origin
              darkreader
              vimium
            ];
          };
        };
      };
    };
}
