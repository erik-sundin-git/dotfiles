{ ... }:
{
  flake.modules.homeManager.gh =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.gh ];
      programs.git.settings."credential \"https://github.com\"".helper =
        "!/usr/bin/env gh auth git-credential";
    };
}
