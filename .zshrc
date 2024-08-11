
# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle :compinstall filename '/home/erik/.zshrc'

autoload -Uz compinit



alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'



compinit
# End of lines added by compinstall
