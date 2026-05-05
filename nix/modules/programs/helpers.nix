{ ... }:
{
  flake.modules.homeManager.uiHelpers =
    { pkgs, ... }:
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
        { summary, body }:
        {
          enter = pkgs.writeShellScript "i3-mode-notif-enter" ''
            notify-send -u low -t 0 --print-id "${summary}" "${body}" > /tmp/i3-mode-notif
          '';
          exit = pkgs.writeShellScript "i3-mode-notif-exit" ''
            dunstctl close "$(cat /tmp/i3-mode-notif 2>/dev/null)" 2>/dev/null
          '';
        };

    };
}
