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

      _module.args.mkScript =
        { exec, interval ? 5, clickLeft ? null }:
        { type = "custom/script"; inherit exec interval; }
        // lib.optionalAttrs (clickLeft != null) { click-left = clickLeft; };
    };
}
