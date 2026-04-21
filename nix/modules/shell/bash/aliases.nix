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
        ssh-desktop = "ssh erik@192.168.1.224";
        rebuild =
          if host == "ether" then
            "sudo nixos-rebuild switch --flake ~/dotfiles#ether"
          else if host == "forge" then
            "home-manager switch -b backup --flake ~/dotfiles#forge"
          else if host == "nomad" then
            "home-manager switch -b backup --flake ~/dotfiles#nomad"
          else
            throw "bash/aliases.nix: unknown host '${host}'";
      };
    };
}
