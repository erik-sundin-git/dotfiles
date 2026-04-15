{
  inputs,
  ...
}:
{
  flake.modules.homeManager.emacs =
    { pkgs, config, ... }:
    let
      dotPath = "${config.systemConstants.configDir}/dotfiles/emacs";
      minimal-emacs = "${config.systemConstants.configDir}/minimal-emacs.d";
    in
    {
      home.file = {
        ".emacs.d/post-early-init.el".source = "/${dotPath}/post-early-init.el";
        ".emacs.d/post-init.el".source = "/${dotPath}/post-init.el";
        ".emacs.d/pre-early-init.el".source = "/${dotPath}/pre-early-init.el";
        ".emacs.d/pre-init.el".source = "/${dotPath}/pre-init.el";
        ".emacs.d/init.el".source = "${minimal-emacs}/init.el";
        ".emacs.d/early-init.el".source = "${minimal-emacs}/early-init.el";
      };

      programs.emacs = {
        enable = true;
      };
    };
}
