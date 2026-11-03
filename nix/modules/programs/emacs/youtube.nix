{ inputs, ... }:
{
  # yt (github:erik-sundin-git/emacs-yt): the YouTube subscription feed in
  # Emacs, played in mpv or VLC. Installs mpv and yt-export-cookies, and adds
  # the elisp package to programs.emacs; post-init.el binds C-c y. Sign in
  # with M-x yt-login using a Chromium profile used only for YouTube.
  flake.modules.homeManager.emacsYoutube =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    let
      # The title and position of what mpv plays, as a notification.
      yt-now-playing = pkgs.writeShellApplication {
        name = "yt-now-playing";
        runtimeInputs = [
          pkgs.playerctl
          pkgs.libnotify
        ];
        text = ''
          info=$(playerctl -p mpv metadata --format \
                   '{{ markup_escape(title) }}  {{ duration(position) }} / {{ duration(mpris:length) }}' \
                   2>/dev/null) || info="Nothing is playing"
          notify-send -u low -a yt -h string:x-dunst-stack-tag:yt -- yt "$info"
        '';
      };

      remote = desc: action: key: {
        inherit key desc;
        action = "exec yt-remote ${action}";
      };
      # Holding a key repeats only seeking: pause or audio only would flap.
      once = b: b // { flags = "--no-repeat"; };
    in
    {
      imports = [ inputs.emacs-yt.homeModules.default ];

      config = lib.mkMerge [
        {
          programs.yt = {
            enable = true;
            installElisp = true;
            # Media keys and waybar control mpv; see swayfx/bindings-data.nix.
            mpris = true;
            # No sway rule: mpv's window tiles like any other.
          };
          home.packages = [ yt-now-playing ];
        }

        # mod+y: the player keys from anywhere, until Space or Escape.
        (lib.optionalAttrs (options ? swayExtraModes) {
          swayExtraModes.yt = {
            entryKey = "y";
            title = "YouTube";
            stayInMode = true;
            bindings = [
              (once (remote "pause" "pause" "k"))
              (once (remote "pause" "pause" "Return"))
              (remote "back 5 s" "seek-backward" "h")
              (remote "forward 5 s" "seek-forward" "l")
              (remote "back 5 s" "seek-backward" "Left")
              (remote "forward 5 s" "seek-forward" "Right")
              (remote "back 1 min" "seek-backward-more" "Shift+h")
              (remote "forward 1 min" "seek-forward-more" "Shift+l")
              (remote "back 1 min" "seek-backward-more" "Down")
              (remote "forward 1 min" "seek-forward-more" "Up")
              (once (remote "next video" "next" "n"))
              (once (remote "previous video" "previous" "p"))
              (once (remote "next chapter" "next-chapter" "period"))
              (once (remote "previous chapter" "previous-chapter" "comma"))
              (once (remote "slower" "slower" "minus"))
              (once (remote "faster" "faster" "plus"))
              (once (remote "normal speed" "normal-speed" "0"))
              (once (remote "undo skip" "unskip" "u"))
              (once (remote "skipping on/off" "toggle-skipping" "Shift+k"))
              (once (remote "audio only/video" "toggle-audio" "m"))
              (once (remote "stop" "stop" "Shift+s"))
              (once (remote "quit mpv" "quit" "Shift+q"))
              (once {
                key = "f";
                desc = "focus mpv";
                action = ''[app_id="^emacs-yt$"] focus'';
              })
              (once {
                key = "i";
                desc = "what's playing";
                action = "exec yt-now-playing";
              })
            ];
          };
        })
      ];
    };
}
