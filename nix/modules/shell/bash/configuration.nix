{ ... }:
{
  flake.modules.homeManager.bash =
    { ... }:
    {
      home.sessionPath = [ "$HOME/.local/bin" ];
      home.sessionVariables.HISTTIMEFORMAT = "%F %T ";

      # Per-project dev shells (`use flake` in .envrc), cached by nix-direnv
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      # Ctrl-R history search, Ctrl-T file picker, Alt-C cd
      programs.fzf.enable = true;

      programs.bash = {
        enable = true;
        enableCompletion = true;

        historySize = 100000;
        historyFileSize = 200000;
        historyControl = [
          "ignoreboth"
          "erasedups"
        ];
        shellOptions = [
          "histappend"
          "checkwinsize"
        ];

        initExtra = ''
          if command -v dircolors > /dev/null 2>&1; then
            test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
            alias ls='ls --color=auto'
          fi

          if [ -z "$SSH_AUTH_SOCK" ] && [ -S "$XDG_RUNTIME_DIR/gcr/ssh" ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
          fi
        '';
      };
    };
}
