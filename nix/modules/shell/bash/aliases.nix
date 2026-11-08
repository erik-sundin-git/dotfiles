{ ... }:
{
  flake.modules.homeManager.bash =
    { config, pkgs, ... }:
    let
      host = config.systemConstants.system.host;
    in
    {
      # A script, not an alias: aliases don't exist in non-interactive shells
      # (`!` commands, Claude sessions). Extra args go to nh (e.g. --dry).
      home.packages = [
        (pkgs.writeShellApplication {
          name = "rebuild";
          runtimeInputs = [ pkgs.nh ];
          text = ''exec nh os switch "$HOME/dotfiles#${host}" "$@"'';
        })
      ];

      programs.bash.shellAliases = {
        ll = "ls -l";
        la = "ls -A";
        l = "ls -CF";

        gs = "git status";
        gc = "git commit -m";
        gp = "git push";
      };
    };
}
