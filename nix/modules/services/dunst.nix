{ ... }:
{
  flake.modules.homeManager.dunst =
    { config, pkgs, ... }:
    let
      c = config.theme;
      frameColor = c.blue;
      # Dunst invokes the script with 6 positional args (appname, summary, body,
      # icon, urgency, raw_icon); we ignore them and just play a sound.
      playSound =
        name:
        toString (
          pkgs.writeShellScript "dunst-sound-${name}" ''
            exec ${pkgs.pulseaudio}/bin/paplay \
              ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/${name}.oga
          ''
        );
    in
    {
      home.packages = [ pkgs.libnotify ];

      services.dunst = {
        enable = true;
        settings = {
          global = {
            frame_color = frameColor;
            separator_color = "frame";
            font = "${c.fontFamily} 10";
            corner_radius = c.rounding;
            frame_width = 2;
          };
          urgency_low = {
            background = c.black;
            foreground = c.brightBlack;
            frame_color = frameColor;
            timeout = 5;
          };
          urgency_normal = {
            background = c.black;
            foreground = c.foreground;
            frame_color = frameColor;
            timeout = 10;
          };
          urgency_critical = {
            background = c.black;
            foreground = c.red;
            frame_color = c.red;
            timeout = 0;
            script = playSound "dialog-warning";
          };
        };
      };
    };
}
