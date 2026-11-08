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
        generic.theme # UI modules read config.theme but don't import it themselves
        homeManager.emacs
        homeManager.mozillaShared # provides the mozillaShared arg to firefox
        homeManager.firefox
        homeManager.bash
        homeManager.starship
        homeManager.nh
        homeManager.ssh
        homeManager.vnc
      ];
      _module.args.isLaptop = isLaptop;

      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = lib.mkDefault "25.11";
      home.username = "erik";

      services.poweralertd.enable = lib.mkDefault isLaptop;

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

      # xresources, not home.file: home.pointerCursor (gtk.nix) adds its own
      # Xcursor properties to the same file
      xresources.properties = lib.mkIf isLaptop { "Xft.dpi" = 144; };

      home.packages = with pkgs; [
        ledger
      ];

      programs.home-manager.enable = true;
      programs.git.enable = true;
      programs.git.signing.format = null;
      programs.git.settings.user.name = config.systemConstants.adminName;
      programs.git.settings.user.email = config.systemConstants.adminEmail;
      programs.git.settings = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        fetch.prune = true;
        rerere.enabled = true;
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
      };

      home.activation.printSystemType = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo -e "\033[33mRebuilt system using profile: ${config.systemConstants.system.type}\033[0m"
      '';

    };
}
