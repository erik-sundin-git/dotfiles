{ ... }:
{
  # Compilers and language tooling for desktops; kept off servers and the ISO
  flake.modules.nixos.devTools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        python3
        gnumake
        clang-tools
        nixfmt
        nixd # Nix language server (eglot in Emacs)
      ];
    };
}
