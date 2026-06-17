#!/usr/bin/env bash

if protonvpn status 2>/dev/null | grep -q '^Server:'; then
  protonvpn disconnect
else
  protonvpn connect
fi
