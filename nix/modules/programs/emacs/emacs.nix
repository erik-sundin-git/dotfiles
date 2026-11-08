{
  inputs,
  ...
}:
{
  flake.modules.homeManager.emacs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.systemConstants.system) type;
      dotPath = "${inputs.self}/nix/assets/emacs.d";
      # Falls back for hosts that pull in emacs without the theme module (live-iso).
      opacity = config.theme.opacity or 1.0;
      fontFamily = config.theme.fontFamily or "DejaVu Sans Mono";
      alphaBg = builtins.floor (opacity * 100);
    in
    {
      options.emacs.texlive = lib.mkEnableOption "texliveFull for Emacs (LaTeX export)" // {
        default = type != "server";
      };

      config.home.file =
        builtins.listToAttrs (
          map
            (f: {
              name = ".emacs.d/${f}";
              value.source = "${dotPath}/${f}";
            })
            [
              "post-init.el"
              "pre-early-init.el"
              "pre-init.el"
              "init.el"
              "early-init.el"
            ]
        )
        // {
          ".emacs.d/nix-theme.el".text = ''
            ;; -*- no-byte-compile: t; lexical-binding: t -*-
            ;; Generated from config.theme in nix. See programs/emacs/emacs.nix.
            (add-to-list 'default-frame-alist '(alpha-background . ${toString alphaBg}))
            ;; The theme's font (config.theme.fontFamily), like the terminal and
            ;; bar; post-init.el sets the size and weight before loading this.
            (set-face-attribute 'default nil :family ${builtins.toJSON fontFamily})
          '';
        };
      config.services.emacs.enable = true;

      # Several GB; for org/LaTeX export on the machines used for writing
      config.home.packages = lib.optionals config.emacs.texlive [ pkgs.texliveFull ];

      config.programs.emacs = {
        enable = true;
        package = lib.mkDefault pkgs.emacs;
        # vterm and pdf-tools have native parts (vterm-module, epdfinfo):
        # prebuilt here instead of compiled at runtime by MELPA's copies,
        # which needed cmake/gcc/libtool (and poppler) on PATH
        extraPackages =
          epkgs: with epkgs; [
            nixfmt
            nix-mode
            ledger-mode
            vterm
            pdf-tools
            # Grammars for the *-ts-modes post-init.el remaps to
            (treesit-grammars.with-grammars (
              g: with g; [
                tree-sitter-bash
                tree-sitter-python
                tree-sitter-json
                tree-sitter-nix
              ]
            ))
          ];
      };
    };
}
