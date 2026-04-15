#!/usr/bin/env bash

# Disk to monitor
DISK="/"

# Fetch disk usage
TOTAL=$(df -h "$DISK" | awk 'NR==2 {print $2}')
USED=$(df -h "$DISK" | awk 'NR==2 {print $3}')
PERCENT=$(df "$DISK" | awk 'NR==2 {print $5}')

# Unicode icon for disk ()
ICON=""

# Output valid JSON for Waybar
printf '{"text":"%s %s","alt":"%s %s"}\n' "$USED/$TOTAL" "$ICON" "$PERCENT%" "$ICON"
