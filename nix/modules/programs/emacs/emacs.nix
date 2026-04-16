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
      home.file = {
        ".emacs.d/post-early-init.el".source = "/${dotPath}/post-early-init.el";
        ".emacs.d/post-init.el".source = "/${dotPath}/post-init.el";
        ".emacs.d/pre-early-init.el".source = "/${dotPath}/pre-early-init.el";
        ".emacs.d/pre-init.el".source = "/${dotPath}/pre-init.el";
        ".emacs.d/init.el".source = "${dotPath}/init.el";
        ".emacs.d/early-init.el".source = "${dotPath}/early-init.el";
      };
      programs.emacs = {
        enable = true;
        extraPackages =
          epkgs: with epkgs; [
            nixfmt
            nix-mode
          ];
      };
    };
}
