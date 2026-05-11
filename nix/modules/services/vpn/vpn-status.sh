#!/usr/bin/env bash

protonvpn status 2>/dev/null | grep '^Server:' | sed 's/Server: \(\S*\).*/VPN: \1/'
