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
    in
    {
      imports = with inputs.self.modules; [
        generic.systemConstants
        generic.colors # consumed by i3, polybar, alacritty — they don't import it themselves
        homeManager.emacs
        homeManager.librewolf
        homeManager.bash
      ];
      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = "23.05";
      home.username = "erik";

      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      home.file.".xinitrc".source = "${inputs.self}/xorg/.xinitrc";

      home.file.".xprofile".text = ''
        setxkbmap se -option ctrl:swapcaps
        ${lib.optionalString isLaptop "xinput set-prop \"Elan Touchpad\" \"libinput Tapping Enabled\" 1"}
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
      home.packages = with pkgs; [ ledger ];

      programs.home-manager.enable = true;
      programs.git.enable = true;
      programs.git.signing.format = null;

      nix.settings.warn-dirty = false;

      home.activation.printSystemType = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo -e "\033[33mRebuilt system using profile: ${config.systemConstants.system.type}\033[0m"
      '';

    };
}
