{ ... }:
{
  flake.modules.homeManager.bash =
    { config, ... }:
    let
      isDesktop = config.systemConstants.currentSystemType == "desktop";
      isLaptop = config.systemConstants.currentSystemType == "laptop";
    in
    {
      programs.bash.shellAliases = {
        ll = "ls -l";
        la = "ls -A";
        l = "ls -CF";
        ssh-desktop = "ssh erik@192.168.1.224";
        rebuild =
          if isDesktop then
            "home-manager switch -b backup --flake ~/dotfiles#debianDesktop"
          else if isLaptop then
            "home-manager switch -b backup --flake ~/dotfiles#debianLaptop"
          else
            throw "bash/aliases.nix: unknown systemType '${config.systemConstants.currentSystemType}'";
      };
    };
}
