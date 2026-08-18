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
          default_target="$HOME/dotfiles/nix/modules/hosts/${host}/${host}.nix"

          pkg=$(wofi --dmenu --prompt "Package to add: " --lines 0 < /dev/null) || exit 0
          [[ -z "$pkg" ]] && exit 0

          target=$(printf '%s\n' \
              "$default_target" \
              "$HOME/dotfiles/nix/modules/hosts/common/nixos/common-desktop.nix" \
              "$HOME/dotfiles/nix/modules/programs/desktop-apps.nix" \
              "$HOME/dotfiles/nix/modules/programs/gaming/gaming.nix" \
              | wofi --dmenu --prompt "Add to file: ") || exit 0
          [[ -z "$target" ]] && exit 0

          prompt="Add the package \`$pkg\` to the appropriate packages list in \`$target\`. If the file has no packages list yet, create one in the correct spot for its module type (environment.systemPackages for NixOS modules, home.packages for Home Manager modules). Preserve the \`with pkgs;\` style if present. After the edit, remind me to run \`rebuild\`."

          exec alacritty --class ai-add-pkg --working-directory "$HOME/dotfiles" \
              -e claude "$prompt"
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
      ]
      ++ waylandScreenshots
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
