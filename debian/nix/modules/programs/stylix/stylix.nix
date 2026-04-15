{ inputs, ... }:

{
  flake.modules.homeManager.stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        image = /home/erik/Pictures/saturn.png;
        polarity = "dark";

        base16Scheme = {
          scheme = "ef-bio";
          author = "Protesilaos Stavrou";
          base00 = "111111"; # bg-main
          base01 = "222522"; # bg-dim
          base02 = "303230"; # bg-alt
          base03 = "808f80"; # fg-dim (comments)
          base04 = "505250"; # bg-active
          base05 = "cfdfd5"; # fg-main
          base06 = "8fcfaf"; # fg-alt
          base07 = "d0ffe0"; # fg-mode-line-active
          base08 = "ef6560"; # red
          base09 = "e09a0f"; # yellow-warmer
          base0A = "d4aa02"; # yellow
          base0B = "3fb83f"; # green
          base0C = "6fc5ef"; # cyan
          base0D = "37aff6"; # blue
          base0E = "d38faf"; # magenta
          base0F = "af9fff"; # magenta-cooler
        };
      };
    };
}
