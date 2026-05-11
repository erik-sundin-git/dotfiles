{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.bleak ]);

  airstatus = pkgs.writeShellScriptBin "airstatus" ''
    exec ${python}/bin/python3 ${./airstatus.py} "$@"
  '';
in
pkgs.writeShellScriptBin "airpods-status" (
  builtins.replaceStrings
    [
      "#!/usr/bin/env bash\n"
      "/home/erik/dev/AirStatus/result/bin/airstatus" # dev path; replaced at build time
    ]
    [
      ""
      "${airstatus}/bin/airstatus"
    ]
    (builtins.readFile ./airpods.sh)
)
