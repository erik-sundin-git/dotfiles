{
  inputs,
  ...
}:
{
  flake.modules.homeManager.commonHome =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";
      kb = config.systemConstants.keyboard;
    in
    {
      imports = with inputs.self.modules; [
        generic.systemConstants
        generic.theme # consumed by i3, polybar, alacritty — they don't import it themselves
        homeManager.emacs
        homeManager.librewolf
        homeManager.firefox
        homeManager.bash
        homeManager.nh
      ];
      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = "25.11";
      home.username = "erik";

      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      home.file.".xinitrc".source = "${inputs.self}/xorg/.xinitrc";

      home.file.".xprofile".text = ''
        setxkbmap ${kb.layout} -option ${kb.options}
        ${lib.optionalString isLaptop "xinput set-prop \"Elan Touchpad\" \"libinput Tapping Enabled\" 1"}

        # per-device pointer acceleration
        for id in $(xinput list --id-only); do
          if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel Speed "; then
            xinput set-prop "$id" "libinput Accel Speed" 0.5
          fi
        done
        xrdb -merge ~/.Xresources
      '';

      home.file.".Xresources".text = lib.optionalString isLaptop "Xft.dpi: 120\n";

      home.file.".local/share/fonts/static".source = "${inputs.self}/fonts";

      home.file.".config/nitrogen/nitrogen.cfg".source = "${inputs.self}/nitrogen/nitrogen.cfg";
      home.packages = with pkgs; [
        ledger
        kdePackages.kdeconnect-kde
      ];

      programs.home-manager.enable = true;
      programs.git.enable = true;
      programs.git.signing.format = null;
      programs.git.settings.user.name = config.systemConstants.adminName;
      programs.git.settings.user.email = config.systemConstants.adminEmail;

      nix.settings.warn-dirty = false;
      nix.settings.substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixgl.cachix.org"
      ];
      nix.settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixgl.cachix.org-1:RXXcaU+XNGCeQw4zAcpG/Iu89yQfA2U0ZLtKExliq0A="
      ];

      home.activation.printSystemType = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo -e "\033[33mRebuilt system using profile: ${config.systemConstants.system.type}\033[0m"
      '';

    };
}
