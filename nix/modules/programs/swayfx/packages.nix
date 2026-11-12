{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      isLaptop,
      swayBindingsData,
      ...
    }:
    let
      c = config.theme;

      # ---- sway-help: rendered from swayBindingsData ----
      keyColWidth = 24;
      pad = s: s + lib.concatStrings (
        builtins.genList (_: " ") (lib.max 1 (keyColWidth - lib.stringLength s))
      );

      # A bind is displayed as either "mod+<key>" or the raw key.
      displayKey = b:
        if (b.mod or true) then "mod+${b.key}" else b.key;

      renderBindRow = b: "  ${pad (displayKey b)}${b.desc}";

      renderSection = s:
        let
          rows =
            if s ? helpSummary
            then map (line: "  ${line}") s.helpSummary
            else map renderBindRow s.binds;
        in
        "${s.title}\n" + lib.concatStringsSep "\n" rows;

      renderMode = _name: m:
        let
          entryMod = m.entryMod or "";
          modPrefix = if entryMod == "" then "" else "${entryMod}+";
          entryDisplay = "mod+${modPrefix}${m.entryKey}";
          innerRows = map (b: "      ${pad b.key}${b.desc}") m.bindings;
        in
        "  ${pad entryDisplay}${m.title} mode\n" + lib.concatStringsSep "\n" innerRows;

      helpBody = lib.concatStringsSep "\n\n" (
        (map renderSection swayBindingsData.sections)
        ++ lib.optional isLaptop (renderSection swayBindingsData.laptopSection)
        ++ [
          ("Modes\n" + lib.concatStringsSep "\n\n"
            (lib.mapAttrsToList renderMode (swayBindingsData.modes // config.swayExtraModes)))
        ]
      );

      hex = lib.removePrefix "#";

      osd = pkgs.writeShellApplication {
        name = "osd";
        runtimeInputs = [
          pkgs.pamixer
          pkgs.brightnessctl
        ];
        text = ''
          # osd volume up|down|mute, osd mic mute, osd brightness up|down
          # "<value>" or "<value> <style>"; wob.sock only exists under sway
          show() {
            local sock="''${XDG_RUNTIME_DIR:?}/wob.sock"
            if [ -p "$sock" ]; then echo "$1''${2:+ $2}" > "$sock"; fi
          }
          muted() { [ "$("$@" --get-mute || true)" = true ] && echo muted || true; }

          case "''${1:-} ''${2:-}" in
            "volume up") pamixer -i 5 ;;
            "volume down") pamixer -d 5 ;;
            "volume mute") pamixer -t ;;
            "mic mute") pamixer --default-source -t ;;
            "brightness up") brightnessctl -q set 5%+ ;;
            "brightness down") brightnessctl -q --min-value=1 set 5%- ;;
            *) echo "usage: osd volume up|down|mute | mic mute | brightness up|down" >&2; exit 2 ;;
          esac

          case "$1" in
            volume) show "$(pamixer --get-volume)" "$(muted pamixer)" ;;
            mic) show "$(pamixer --default-source --get-volume)" "$(muted pamixer --default-source)" ;;
            brightness) show "$(brightnessctl -m | cut -d, -f4 | tr -d %)" ;;
          esac
        '';
      };

      sway-help = pkgs.writeShellApplication {
        name = "sway-help";
        runtimeInputs = [ pkgs.fuzzel ];
        text = ''
          # Read-only shortcut cheatsheet. Selecting a row is a no-op — this is
          # just a viewer. All rows are generated from swayBindingsData, so
          # adding a bind in bindings-data.nix updates this list automatically.
          fuzzel --dmenu \
              --prompt "Sway shortcuts: " \
              --width 80 --lines 30 \
              > /dev/null <<'EOF' || true
          ${helpBody}
          EOF
        '';
      };
    in
    {
      home.packages = [
        sway-help
        osd
      ];

      # Volume/brightness OSD: wob reads "<percent> [style]" lines from a
      # socket-activated FIFO (%t/wob.sock, HM's wob units on
      # sway-session.target). The media keys run `osd`, which changes the
      # level and writes it there.
      services.wob = {
        enable = true;
        settings = {
          "" = {
            anchor = "bottom";
            margin = 120;
            width = 360;
            height = 28;
            border_size = 1;
            border_offset = 0;
            bar_padding = 4;
            max = 100;
            border_color = hex c.accent;
            background_color = hex c.background + "e6";
            bar_color = hex c.accent;
          };
          "style.muted".bar_color = hex c.black;
        };
      };
    };
}
