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
        { name, args ? "" }:
        pkgs.writeShellScriptBin name ''
          mkdir -p ~/Pictures/Screenshots
          f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
          maim ${args} | tee "$f" | xclip -selection clipboard -t image/png
        '';

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
          body = lib.concatStringsSep "\n" (
            map (b: "${rightPad keyWidth b.key}  ${b.description}") bindings
          );
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
