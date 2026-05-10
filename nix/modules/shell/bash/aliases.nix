{ ... }:
{
  flake.modules.homeManager.bash =
    { config, ... }:
    let
      host = config.systemConstants.system.host;
    in
    {
      programs.bash.shellAliases = {
        ll = "ls -l";
        la = "ls -A";
        l = "ls -CF";

        gs = "git status";
        gc = "git commit -m";
        gp = "git push";

        ssh-desktop = "ssh erik@${config.systemConstants.network.forgeHost}";
        rebuild =
          if host == "ether" || host == "specter" then
            "nh os switch ~/dotfiles#${host}"
          else
            "nh home switch ~/dotfiles -c ${host}";
      };
    };
}
