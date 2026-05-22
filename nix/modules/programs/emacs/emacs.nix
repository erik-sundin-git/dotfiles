{
  inputs,
  ...
}:
{
  flake.modules.homeManager.emacs =
    { pkgs, lib, config, ... }:
    let
      dotPath = "${inputs.self}/emacs/.emacs.d";
    in
    {
      home.file = builtins.listToAttrs (
        map (f: {
          name = ".emacs.d/${f}";
          value.source = "${dotPath}/${f}";
        }) [
          "post-early-init.el"
          "post-init.el"
          "pre-early-init.el"
          "pre-init.el"
          "init.el"
          "early-init.el"
        ]
      );
      services.emacs.enable = true;

      # Build tools needed by emacs packages compiled at runtime (e.g. vterm-module)
      home.packages = with pkgs; [
        cmake
        gcc
        gnumake
        libtool
      ];

      programs.emacs = {
        enable = true;
        package = lib.mkDefault pkgs.emacs;
        extraPackages =
          epkgs: with epkgs; [
            nixfmt
            nix-mode
            ledger-mode
          ];
      };
    };
}
