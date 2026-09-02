{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      pkgs,
      waylandScreenshots,
      ...
    }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";
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

      sway-help = pkgs.writeShellApplication {
        name = "sway-help";
        runtimeInputs = [ pkgs.wofi ];
        text = ''
          # Read-only shortcut cheatsheet. Selecting a row is a no-op — this is
          # just a viewer. Update this list when adding/removing custom binds.
          wofi --dmenu \
              --prompt "Sway shortcuts" \
              --width 700 --height 500 \
              --insensitive > /dev/null <<'EOF' || true
          mod+Return          Terminal (alacritty)
          mod+d               App launcher (wofi drun)
          mod+Shift+q         Kill focused window
          mod+Shift+a         Add nix package (interactive claude flow)
          mod+F1              This help menu

          mod+h / j / k / l           Focus left / down / up / right
          mod+Shift+h / j / k / l     Move window left / down / up / right
          mod+b                       Split horizontal
          mod+v                       Split vertical

          mod+1 .. 9              Switch to workspace N
          mod+Shift+1 .. 9        Move focused window to workspace N
          mod+m / Shift+m         Workspace mail / move to mail
          mod+e / Shift+e         Workspace emacs / move to emacs

          Print                   Screenshot area
          mod+Print               Screenshot full screen

          XF86AudioRaiseVolume    Volume up
          XF86AudioLowerVolume    Volume down
          XF86AudioMute           Mute toggle

          XF86MonBrightnessUp     Screen brightness up (laptop)
          XF86MonBrightnessDown   Screen brightness down (laptop)
          mod+XF86MonBrightness*  Keyboard backlight up/down (laptop)
          EOF
        '';
      };
    in
    {
      home.packages = [
        pkgs.wofi
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
