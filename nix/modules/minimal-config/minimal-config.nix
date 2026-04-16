{
  inputs,
  ...
}:
{
  # default settings needed for all homeManagerConfigurations

  flake.modules.homeManager.minimal-config =
    { config, lib,  ... }:
    let
      isLaptop = config.systemConstants.isLaptop;
    in
    {
      imports = [inputs.self.modules.generic.systemConstants];
      home.homeDirectory = "/home/${config.home.username}";
      home.stateVersion = "23.05";
      # home.keyboard = {
      #   layout = "se";
      #   options = ["ctrl:swapcaps"];
      # };
      # xsession.enable = true;

      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      home.file = {
        ".xinitrc".source = "${inputs.self}/xorg/.xinitrc";
        ".xprofile".text = ''
          setxkbmap se -option ctrl:swapcaps
          ${lib.optionalString isLaptop "xinput set-prop \"Elan Touchpad\" \"libinput Tapping Enabled\" 1"}
          xrdb -merge ~/.Xresources
        '';
        ".Xresources".text = lib.optionalString isLaptop "Xft.dpi: 120\n";
      };

      programs.home-manager.enable = true;

    };
}
