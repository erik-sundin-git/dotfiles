{
  flake.modules.homeManager.shell =
    { pkgs, config, ... }:
    {
      home.packages = with pkgs; [ zsh-powerlevel10k ];

      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        enableCompletion = true;
        autosuggestion.enable = true;

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "dirhistory"
            "history"
          ];
        };
      };

      programs.bash = {
        enable = true;
        enableCompletion = true;
      };
    };

}
