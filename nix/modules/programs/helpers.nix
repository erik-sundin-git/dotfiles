{ ... }:
{
  flake.modules.homeManager.uiHelpers =
    { pkgs, lib, ... }:
    {
      _module.args.mkColors =
        {
          border,
          background ? border,
          text,
          indicator ? border,
          childBorder ? border,
        }:
        {
          inherit
            border
            background
            text
            indicator
            childBorder
            ;
        };

      _module.args.mkScreenshot =
        {
          name,
          args ? "",
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.maim
            pkgs.xclip
          ];
          text = ''
            mkdir -p ~/Pictures/Screenshots
            f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
            maim ${args} | tee "$f" | xclip -selection clipboard -t image/png
          '';
        };

      _module.args.waylandScreenshots = [
        (pkgs.writeShellApplication {
          name = "screenshot-area";
          runtimeInputs = [
            pkgs.grim
            pkgs.slurp
            pkgs.wl-clipboard
          ];
          text = ''
            mkdir -p ~/Pictures/Screenshots
            f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
            grim -g "$(slurp)" - | tee "$f" | wl-copy
          '';
        })
        (pkgs.writeShellApplication {
          name = "screenshot-full";
          runtimeInputs = [
            pkgs.grim
            pkgs.wl-clipboard
          ];
          text = ''
            mkdir -p ~/Pictures/Screenshots
            f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
            grim - | tee "$f" | wl-copy
          '';
        })
      ];

      _module.args.hexToHyprRgb = hex: "rgb(${lib.removePrefix "#" hex})";

      _module.args.hexToRgba =
        hex: alpha:
        let
          fromHex =
            s:
            let
              d = {
                "0" = 0;
                "1" = 1;
                "2" = 2;
                "3" = 3;
                "4" = 4;
                "5" = 5;
                "6" = 6;
                "7" = 7;
                "8" = 8;
                "9" = 9;
                "a" = 10;
                "b" = 11;
                "c" = 12;
                "d" = 13;
                "e" = 14;
                "f" = 15;
              };
              hi = d.${lib.toLower (lib.substring 0 1 s)};
              lo = d.${lib.toLower (lib.substring 1 1 s)};
            in
            hi * 16 + lo;
          h = lib.removePrefix "#" hex;
        in
        "rgba(${toString (fromHex (lib.substring 0 2 h))}, ${toString (fromHex (lib.substring 2 2 h))}, ${
          toString (fromHex (lib.substring 4 2 h))
        }, ${alpha})";

      _module.args.mkModeNotif =
        { modeTitle, bindings }:
        let
          keyWidth = lib.foldl (acc: b: lib.max acc (lib.stringLength b.key)) 0 bindings;
          rightPad =
            width: str:
            let
              padding = lib.max 0 (width - lib.stringLength str);
            in
            str + lib.concatStrings (builtins.genList (_: " ") padding);
          body = lib.concatStringsSep "\n" (map (b: "${rightPad keyWidth b.key}  ${b.description}") bindings);
        in
        {
          enter = pkgs.writeShellScript "i3-mode-notif-enter" ''
            notify-send -u low -t 0 --print-id "${modeTitle}" "${body}" > $XDG_RUNTIME_DIR/i3-mode-notif
          '';
          exit = pkgs.writeShellScript "i3-mode-notif-exit" ''
            dunstctl close "$(cat $XDG_RUNTIME_DIR/i3-mode-notif 2>/dev/null)" 2>/dev/null
          '';
        };

    };
}
