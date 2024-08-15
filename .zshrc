


export DOTFILES="/home/erik/.config"
source $HOME/completion.zsh


### Aliases ###
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias gs='git status'
alias ga='git add'
alias gp='git push'


#eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
compinit
# End of lines added by compinstall
