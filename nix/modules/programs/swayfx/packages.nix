{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      hexToRgba,
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

      renderMode = name: m:
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

      sway-help = pkgs.writeShellApplication {
        name = "sway-help";
        runtimeInputs = [ pkgs.wofi ];
        text = ''
          # Read-only shortcut cheatsheet. Selecting a row is a no-op — this is
          # just a viewer. All rows are generated from swayBindingsData, so
          # adding a bind in bindings-data.nix updates this list automatically.
          wofi --dmenu \
              --prompt "Sway shortcuts" \
              --width 700 --height 600 \
              --insensitive > /dev/null <<'EOF' || true
          ${helpBody}
          EOF
        '';
      };
    in
    {
      home.packages = [ sway-help ];

      # User service with Restart=always: swayosd-server panics in GTK
      # (gtk_widget_map) now and then, which killed the OSD for the session
      services.swayosd = {
        enable = true;
        # swayosd's stock CSS, recolored from the theme
        stylePath = pkgs.writeText "swayosd.css" ''
          window#osd {
            border-radius: 999px;
            border: 1px solid ${c.accent};
            background: ${hexToRgba c.background "0.9"};
          }
          window#osd #container {
            margin: 16px;
          }
          window#osd image,
          window#osd label {
            color: ${c.foreground};
          }
          window#osd progressbar:disabled,
          window#osd image:disabled {
            opacity: 0.5;
          }
          window#osd progressbar,
          window#osd segmentedprogress {
            min-height: 6px;
            border-radius: 999px;
            background: transparent;
            border: none;
          }
          window#osd trough,
          window#osd segment {
            min-height: inherit;
            border-radius: inherit;
            border: none;
            background: ${c.black};
          }
          window#osd progress,
          window#osd segment.active {
            min-height: inherit;
            border-radius: inherit;
            border: none;
            background: ${c.accent};
          }
          window#osd segment {
            margin-left: 8px;
          }
          window#osd segment:first-child {
            margin-left: 0;
          }
        '';
      };
    };
}
