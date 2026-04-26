{
  flake.modules.nixos.cliTools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        alacritty
        htop
        nixfmt
        home-manager
        parted
      ];
    };
}
