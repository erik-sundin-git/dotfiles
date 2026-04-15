#!/usr/bin/env sh

qtile start
xrandr --output DVI-I-2-2 --mode 1920x1080 --right-of DVI-I-1-1
xrandr --output DVI-I-1-1 --mode 3440x1440 --primary --right-of eDP-1
picom &
polybar &
