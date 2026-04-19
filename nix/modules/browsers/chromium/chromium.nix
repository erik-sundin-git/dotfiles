{
  inputs,
  ...
}:
{
  flake.modules.homeManager.chromium =
    { pkgs, config, ... }:

    {

      programs.chromium = {
        enable = true;
        package = pkgs.ungoogled-chromium;

        extensions = [
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        ];
      };
    };
}
