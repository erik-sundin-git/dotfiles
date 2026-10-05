{ writeShellScriptBin, flatpak }:

writeShellScriptBin "geforcenow" ''
  exec ${flatpak}/bin/flatpak run com.nvidia.geforcenow "$@"
''
