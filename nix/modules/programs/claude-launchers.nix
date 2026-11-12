{ ... }:
{
  # nix-add-package and claude-prompt: hand a question or a package edit to a
  # claude session in a floating foot (app_id ai-add-pkg / ai-prompt, floated
  # by sway). Without arguments they ask with fuzzel (sway's binds). EXWM has
  # no foot: it asks in the minibuffer, takes the targets and the prompt from
  # `nix-add-package --list-targets / --print-prompt`, and runs claude in
  # vterm. foot comes from the WM stack's PATH, not runtimeInputs, so EXWM
  # hosts don't get it. Only sets
  # home.packages, so importing it from more than one module is harmless.
  flake.modules.homeManager.claudeLaunchers =
    {
      config,
      pkgs,
      pkgsUnstable,
      ...
    }:
    let
      host = config.systemConstants.system.host;

      nix-add-package = pkgs.writeShellApplication {
        name = "nix-add-package";
        runtimeInputs = [
          pkgs.fuzzel
          pkgsUnstable.claude-code
        ];
        text = ''
          # Pick a nixpkgs package name and a target file, then hand off to
          # claude to make the edit. Bound to mod+Shift+a.
          #   nix-add-package [PKG [LABEL]]   ask (fuzzel) for whatever is missing
          #   nix-add-package --list-targets  print the target labels
          #   nix-add-package --print-prompt PKG LABEL
          #                                   print claude's prompt, don't run it

          # Friendly labels → real paths, in menu order (associative array
          # iteration is unordered, so the order lives in `labels`).
          labels=(
            "this host (${host}.nix)"
            "system-wide (common-desktop.nix)"
            "user apps (desktop-apps.nix)"
            "gaming (gaming.nix)"
          )
          declare -A targets=(
            ["this host (${host}.nix)"]="$HOME/dotfiles/nix/modules/hosts/${host}/${host}.nix"
            ["system-wide (common-desktop.nix)"]="$HOME/dotfiles/nix/modules/hosts/common/nixos/common-desktop.nix"
            ["user apps (desktop-apps.nix)"]="$HOME/dotfiles/nix/modules/programs/desktop-apps.nix"
            ["gaming (gaming.nix)"]="$HOME/dotfiles/nix/modules/programs/gaming/gaming.nix"
          )

          if [[ "''${1:-}" == "--list-targets" ]]; then
            printf '%s\n' "''${labels[@]}"
            exit 0
          fi

          print_prompt=false
          if [[ "''${1:-}" == "--print-prompt" ]]; then
            print_prompt=true
            shift
            if [[ $# -ne 2 ]]; then
              echo "usage: nix-add-package --print-prompt PKG LABEL" >&2
              exit 2
            fi
          fi

          if [[ $# -ge 1 ]]; then
            pkg=$1
          else
            pkg=$(fuzzel --dmenu \
                --prompt-only "nixpkgs package (e.g. htop): " \
                < /dev/null) || exit 0
          fi
          [[ -z "$pkg" ]] && exit 0

          if [[ $# -ge 2 ]]; then
            label=$2
          else
            label=$(printf '%s\n' "''${labels[@]}" \
                | fuzzel --dmenu --prompt "Add \"$pkg\" to: ") || exit 0
          fi
          [[ -z "$label" ]] && exit 0
          if [[ ! -v targets["$label"] ]]; then
            echo "nix-add-package: unknown target: $label" >&2
            exit 2
          fi
          target="''${targets[$label]}"

          prompt="Add the package \`$pkg\` to the appropriate packages list in \`$target\`. If the file has no packages list yet, create one in the correct spot for its module type (environment.systemPackages for NixOS modules, home.packages for Home Manager modules). Preserve the \`with pkgs;\` style if present. After the edit, remind me to run \`rebuild\`."

          if $print_prompt; then
            printf '%s\n' "$prompt"
            exit 0
          fi

          exec foot --app-id ai-add-pkg --working-directory "$HOME/dotfiles" \
              claude "$prompt"
        '';
      };

      claude-prompt = pkgs.writeShellApplication {
        name = "claude-prompt";
        runtimeInputs = [
          pkgs.fuzzel
          pkgsUnstable.claude-code
        ];
        text = ''
          # Quick prompt: answer a question in a floating claude session (you
          # can keep chatting). Bound to mod+c.
          #   claude-prompt [PROMPT]   ask (fuzzel) when no prompt is given
          if [[ $# -ge 1 ]]; then
            prompt=$1
          else
            prompt=$(fuzzel --dmenu \
                --prompt-only "Ask claude: " \
                < /dev/null) || exit 0
          fi
          [[ -z "$prompt" ]] && exit 0

          exec foot --app-id ai-prompt --working-directory "$HOME/dotfiles" \
              claude "$prompt"
        '';
      };
    in
    {
      home.packages = [
        nix-add-package
        claude-prompt
      ];
    };
}
