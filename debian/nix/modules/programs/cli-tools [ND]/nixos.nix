{
  flake.modules.nixos.cli-tools =
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
