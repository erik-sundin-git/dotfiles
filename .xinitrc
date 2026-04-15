#!/bin/sh

# Make sure this is before the 'exec' command or it won't be sourced.
[ -f /etc/xprofile ] && . /etc/xprofile
[ -f ~/.xprofile ] && . ~/.xprofile

eval $(ssh-agent -s)
export SSH_ASKPASS=/usr/bin/ssh-askpass
export SSH_ASKPASS_REQUIRE=prefer
ssh-add ~/.ssh/id_ed25519

exec i3
