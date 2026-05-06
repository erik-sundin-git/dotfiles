{
  inputs,
  ...
}:
{
  flake.modules.homeManager.emacs =
    { pkgs, config, ... }:
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

      programs.emacs = {
        enable = true;
        package = pkgs.emacs-git;
        extraPackages =
          epkgs: with epkgs; [
            nixfmt
            nix-mode
            ledger-mode
          ];
      };
    };
}
