{ ... }:
{
  # `vnc <host>` opens the VNC console of every inventory entry that sets `vnc` (nix/secrets/hosts.nix)
  flake.modules.homeManager.vnc =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      consoles = lib.filterAttrs (_: h: h.vnc != null) config.systemConstants.network.hosts;
      # tigervnc takes a raw port as host::port
      toTiger = addr: builtins.replaceStrings [ ":" ] [ "::" ] addr;
    in
    {
      home.packages = with pkgs; [
        tigervnc
        (writeShellApplication {
          name = "vnc";
          runtimeInputs = [ tigervnc ];
          text = ''
            case "''${1:-}" in
            ${lib.concatStrings (
              lib.mapAttrsToList (name: h: ''
                ${name}) exec vncviewer ${lib.escapeShellArg (toTiger h.vnc)} ;;
              '') consoles
            )}
              *) echo "usage: vnc {${lib.concatStringsSep "|" (lib.attrNames consoles)}}" >&2; exit 1 ;;
            esac
          '';
        })
      ];
    };
}
