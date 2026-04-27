{
  inputs,
  ...
}:
{
  flake.modules.homeManager.bash =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.bash = {
        enable = true;
        enableCompletion = true;

        historySize = 1000;
        historyFileSize = 2000;
        historyControl = [ "ignoreboth" ];
        shellOptions = [
          "histappend"
          "checkwinsize"
        ];

        initExtra = ''
          if command -v dircolors > /dev/null 2>&1; then
            test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
            alias ls='ls --color=auto'
          fi

          export PATH="$HOME/.local/bin:$PATH"
          eval "$(starship init bash)"
        '';
      };
    };
}
