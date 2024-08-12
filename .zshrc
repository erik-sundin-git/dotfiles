source /usr/share/zsh/share/antigen.zsh
# The following lines were added by compinstall

zstyle ':completion:*' completer
zstyle :compinstall filename '/home/erik/.zshrc'

autoload -Uz compinit

export PATH=$PATH:/home/erik/.config/emacs/bin

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
antigen bundle zsh-users/zsh-autosuggestions
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
compinit
# End of lines added by compinstall
