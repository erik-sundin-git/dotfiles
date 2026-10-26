{ ... }:
{
  # nmtui (newt) paints with the terminal's 16 ANSI colors, so the theme's
  # palette in alacritty recolors it. Pin newt's stock palette to fixed
  # xterm-256 cube entries, which the theme doesn't touch.
  flake.modules.homeManager.nmtui =
    { lib, pkgs, ... }:
    let
      black = "color16";
      white = "color231";
      gray = "color248";
      blue = "color19";
      red = "color124";
      brown = "color130";
      palette = {
        root = "${white},${blue}";
        border = "${black},${gray}";
        window = "${black},${gray}";
        shadow = "${white},${black}";
        title = "${red},${gray}";
        button = "${gray},${red}";
        actbutton = "${red},${gray}";
        checkbox = "${gray},${blue}";
        actcheckbox = "${gray},${red}";
        entry = "${gray},${blue}";
        label = "${blue},${gray}";
        listbox = "${black},${gray}";
        actlistbox = "${gray},${blue}";
        textbox = "${black},${gray}";
        acttextbox = "${gray},${red}";
        helpline = "${white},${blue}";
        roottext = "${gray},${blue}";
        emptyscale = ",${red}";
        fullscale = ",${blue}";
        disentry = "${blue},${gray}";
        compactbutton = "${black},${gray}";
        actsellistbox = "${gray},${red}";
        sellistbox = "${black},${brown}";
      };
      newtColors = lib.concatStringsSep ";" (lib.mapAttrsToList (k: v: "${k}=${v}") palette);
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "nmtui" ''
          NEWT_COLORS='${newtColors}' exec ${pkgs.networkmanager}/bin/nmtui "$@"
        '')
      ];
    };
}
