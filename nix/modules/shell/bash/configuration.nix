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

          if [ -z "$SSH_AUTH_SOCK" ] && [ -S "$XDG_RUNTIME_DIR/gcr/ssh" ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
          fi
        '';
      };
    };
}
