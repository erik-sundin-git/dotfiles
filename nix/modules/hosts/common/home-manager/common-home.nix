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
        homeManager.mozillaShared # provides the mozillaShared arg to librewolf + firefox
        homeManager.librewolf
        homeManager.firefox
        homeManager.bash
        homeManager.nh
        homeManager.ssh
      ];
      _module.args.isLaptop = isLaptop;

      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = "25.11";
      home.username = "erik";

      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      services.poweralertd.enable = isLaptop;

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

      home.packages = with pkgs; [
        ledger
      ];

      programs.home-manager.enable = true;
      programs.git.enable = true;
      programs.git.signing.format = null;
      programs.git.settings.user.name = config.systemConstants.adminName;
      programs.git.settings.user.email = config.systemConstants.adminEmail;

      nix.settings.warn-dirty = false;

      home.activation.printSystemType = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo -e "\033[33mRebuilt system using profile: ${config.systemConstants.system.type}\033[0m"
      '';

    };
}
