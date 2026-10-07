{ ... }:
{
  flake.modules.homeManager.wofi =
    { config, pkgs, hexToRgba, ... }:
    let
      c = config.theme;
      radius = toString c.rounding;
      innerRadius = toString (c.rounding / 2);
    in
    {
      home.packages = [ pkgs.wofi ];

      xdg.configFile."wofi/config".text = ''
        show=drun
        prompt=Run
        width=600
        height=400
        allow_images=true
        insensitive=true
        gtk_dark=true
      '';

      xdg.configFile."wofi/style.css".text = ''
        * {
          font-family: "${c.fontFamily}";
          font-size: 13px;
        }

        window {
          background-color: ${hexToRgba c.superDark (if c.blur then "0.85" else "1.0")};
          border: 1px solid ${c.blue};
          border-radius: ${radius}px;
          color: ${c.foreground};
        }

        #input {
          margin: 6px;
          padding: 6px 8px;
          background-color: ${c.black};
          color: ${c.foreground};
          border: none;
          border-radius: ${innerRadius}px;
        }

        #inner-box,
        #outer-box {
          margin: 4px;
        }

        #scroll {
          margin: 0;
        }

        #text {
          color: ${c.foreground};
          padding: 2px 4px;
        }

        #entry {
          padding: 4px 6px;
          border-radius: ${innerRadius}px;
        }

        #entry:selected {
          background-color: ${c.blue};
        }

        #entry:selected #text {
          color: ${c.black};
        }
      '';
    };
}
