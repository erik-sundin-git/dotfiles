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
        ssh-desktop = "ssh erik@${config.systemConstants.network.forgeHost}";
        rebuild =
          if host == "ether" then "nh os switch ~/dotfiles -c ${host}"
          else "nh home switch ~/dotfiles -c ${host}";
      };
    };
}
