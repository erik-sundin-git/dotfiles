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
          n = builtins.length bindings;
          colWidths = builtins.genList (
            i:
            let
              b = lib.elemAt bindings i;
              w = lib.max (lib.stringLength b.key) (lib.stringLength b.description);
            in
            if i == n - 1 then w else w + 2
          ) n;
          rightPad =
            width: str:
            str + lib.concatStrings (builtins.genList (_: " ") (lib.max 0 (width - lib.stringLength str)));
          mkRow =
            getter:
            lib.concatStrings (
              builtins.genList (i: rightPad (lib.elemAt colWidths i) (getter (lib.elemAt bindings i))) n
            );
          body = "${mkRow (b: b.key)}\n${mkRow (b: b.description)}";
        in
        {
          enter = pkgs.writeShellScript "i3-mode-notif-enter" ''
            notify-send -u low -t 0 --print-id "${modeTitle}" "${body}" > /tmp/i3-mode-notif
          '';
          exit = pkgs.writeShellScript "i3-mode-notif-exit" ''
            dunstctl close "$(cat /tmp/i3-mode-notif 2>/dev/null)" 2>/dev/null
          '';
        };

    };
}
