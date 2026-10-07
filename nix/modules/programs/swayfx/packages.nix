{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      waylandScreenshots,
      isLaptop,
      swayBindingsData,
      ...
    }:
    let
      host = config.systemConstants.system.host;

      nix-add-package = pkgs.writeShellApplication {
        name = "nix-add-package";
        runtimeInputs = [
          pkgs.wofi
          pkgs.alacritty
          pkgs.claude-code
        ];
        text = ''
          # Interactive helper: pick a nixpkgs package name and a target file,
          # then hand off to claude to make the edit. Bound to mod+Shift+a.

          default_target="$HOME/dotfiles/nix/modules/hosts/${host}/${host}.nix"

          pkg=$(wofi --dmenu \
              --prompt "nixpkgs package (e.g. htop): " \
              --lines 0 < /dev/null) || exit 0
          [[ -z "$pkg" ]] && exit 0

          # Friendly labels → real paths. Selecting a label maps back to the path.
          declare -A targets=(
            ["this host (${host}.nix)"]="$default_target"
            ["system-wide (common-desktop.nix)"]="$HOME/dotfiles/nix/modules/hosts/common/nixos/common-desktop.nix"
            ["user apps (desktop-apps.nix)"]="$HOME/dotfiles/nix/modules/programs/desktop-apps.nix"
            ["gaming (gaming.nix)"]="$HOME/dotfiles/nix/modules/programs/gaming/gaming.nix"
          )
          # Print keys in a fixed order — associative array iteration is unordered.
          label=$(printf '%s\n' \
              "this host (${host}.nix)" \
              "system-wide (common-desktop.nix)" \
              "user apps (desktop-apps.nix)" \
              "gaming (gaming.nix)" \
              | wofi --dmenu --prompt "Add \"$pkg\" to: ") || exit 0
          [[ -z "$label" ]] && exit 0
          target="''${targets[$label]}"

          prompt="Add the package \`$pkg\` to the appropriate packages list in \`$target\`. If the file has no packages list yet, create one in the correct spot for its module type (environment.systemPackages for NixOS modules, home.packages for Home Manager modules). Preserve the \`with pkgs;\` style if present. After the edit, remind me to run \`rebuild\`."

          exec alacritty --class ai-add-pkg --working-directory "$HOME/dotfiles" \
              -e claude "$prompt"
        '';
      };

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
          modPrefix = if m.entryMod == "" then "" else "${m.entryMod}+";
          entryDisplay = "mod+${modPrefix}${m.entryKey}";
          innerRows = map (b: "      ${pad b.key}${b.desc}") m.bindings;
        in
        "  ${pad entryDisplay}${m.title} mode\n" + lib.concatStringsSep "\n" innerRows;

      helpBody = lib.concatStringsSep "\n\n" (
        (map renderSection swayBindingsData.sections)
        ++ lib.optional isLaptop (renderSection swayBindingsData.laptopSection)
        ++ [
          ("Modes\n" + lib.concatStringsSep "\n\n"
            (lib.mapAttrsToList renderMode swayBindingsData.modes))
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
      home.packages = [
        pkgs.jq
        pkgs.pavucontrol
        pkgs.swayosd
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
        pkgs.nerd-fonts.jetbrains-mono
        nix-add-package
        sway-help
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
