#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dpkg --get-selections | grep -v deinstall | awk '{print $1}' | sort > "$SCRIPT_DIR/installed_packages.txt"
