{
  flake.modules.homeManager.office =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pdfarranger
        notesnook
        libreoffice-qt6
        gimp3-with-plugins
      ];
    };
}
