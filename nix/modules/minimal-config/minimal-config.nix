{
  inputs,
  ...
}:
{
  # default settings needed for all homeManagerConfigurations

  flake.modules.homeManager.minimal-config =
    { config, lib, pkgs, ... }:
    let
      isLaptop = config.systemConstants.currentSystemType == "laptop";
    in
    {
      imports = with inputs.self.modules.homeManager; [
        inputs.self.modules.generic.systemConstants
        emacs
        librewolf
        bash
        i3
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
        xrdb -merge ~/.Xresources
      '';

      home.file.".Xresources".text = lib.optionalString isLaptop "Xft.dpi: 120\n";

      home.file.".local/share/fonts".source = "${inputs.self}/fonts";

      home.file.".config/nitrogen/nitrogen.cfg".source = "${inputs.self}/nitrogen/nitrogen.cfg";
      programs.home-manager.enable = true;

      nix.package = pkgs.nix;
      nix.settings.warn-dirty = false;

      home.activation.printSystemType = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo -e "\033[33mRebuilt system using profile: ${config.systemConstants.currentSystemType}\033[0m"
      '';

    };
}
