{
  inputs,
  ...
}:
{
  flake.modules.homeManager.emacs =
    { pkgs, lib, config, ... }:
    let
      dotPath = "${inputs.self}/emacs/.emacs.d";
      # Falls back for hosts that pull in emacs without the theme module (live-iso).
      opacity = config.theme.opacity or 1.0;
      alphaBg = builtins.floor (opacity * 100);
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
      ) // {
        ".emacs.d/nix-theme.el".text = ''
          ;; Generated from config.theme in nix. See programs/emacs/emacs.nix.
          (add-to-list 'default-frame-alist '(alpha-background . ${toString alphaBg}))
        '';
      };
      services.emacs.enable = true;

      # Build tools needed by emacs packages compiled at runtime (e.g. vterm-module)
      home.packages = with pkgs; [
        cmake
        gcc
        gnumake
        libtool
        texlive.combined.scheme-full
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
