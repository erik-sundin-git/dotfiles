{
  flake.modules.homeManager.browser =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages =
        with pkgs;
        [ firefox ]
        ++ lib.optionals (stdenv.hostPlatform.system == "aarch64-linux") [ chromium ];
    };
}
