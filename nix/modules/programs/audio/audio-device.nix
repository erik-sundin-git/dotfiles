{ ... }:
{
  # Audio tools for every WM that uses swayBindingsData (sway, i3, EXWM):
  # pulsemixer as the mixer, and `audio-device output|input`, the picker
  # behind mod+o a / mod+o m. It lists PulseAudio sinks or sources in fuzzel
  # (dmenu without Wayland), sets the default and moves the running streams
  # over, since PulseAudio's set-default doesn't move them.
  flake.modules.homeManager.swayBindings =
    { pkgs, ... }:
    let
      audio-device = pkgs.writeShellApplication {
        name = "audio-device";
        runtimeInputs = with pkgs; [
          pulseaudio
          jq
          fuzzel
          dmenu
          libnotify
        ];
        text = ''
          kind="''${1:-output}"
          case "$kind" in
            output) t=sink; streams=sink-input ;;
            input) t=source; streams=source-output ;;
            *) echo "usage: audio-device [output|input]" >&2; exit 2 ;;
          esac

          menu() {
            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              fuzzel --dmenu --prompt "$1"
            else
              dmenu -i -p "$1"
            fi
          }

          # Monitor sources are just the sinks' loopbacks
          devices=$(pactl -f json list "''${t}s" \
            | jq -c '[.[] | select(.name | endswith(".monitor") | not)]')
          current=$(pactl "get-default-$t")

          choice=$(jq -r --arg cur "$current" \
              '.[] | (if .name == $cur then "* " else "  " end) + .description' \
              <<<"$devices" \
            | menu "Audio $kind: ") || exit 0
          name=$(jq -r --arg d "''${choice:2}" \
            'first(.[] | select(.description == $d) | .name) // empty' <<<"$devices")
          [ -n "$name" ] || exit 0

          pactl "set-default-$t" "$name"
          pactl list short "''${streams}s" | cut -f1 | while read -r id; do
            pactl "move-$streams" "$id" "$name" || true
          done
          notify-send -t 2000 "Audio $kind" "''${choice:2}" || true
        '';
      };
    in
    {
      home.packages = [
        audio-device
        pkgs.pulsemixer
      ];
    };
}
