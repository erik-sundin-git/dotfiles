{ inputs, ... }:
{
  flake.installer.features.gaming = {
    label = "Gaming: Steam, latest kernel, GeForce NOW, Prism";
    order = 10;
  };

  flake.modules.nixos.gaming =
    {
      config,
      lib,
      pkgs,
      pkgsUnstable,
      ...
    }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      imports = [ inputs.self.modules.nixos.geforcenow ];

      # Off on nomad: 1.5G (plus a JDK 17) for RuneScape
      options.gaming.boltLauncher = lib.mkEnableOption "Bolt, the RuneScape launcher" // {
        default = true;
      };

      config = {
        programs.nix-ld.libraries = with pkgs; [
          libGL
          mesa
          libx11
          libxrandr
          libxcursor
          libxi
          libxext
          libxtst
          libxxf86vm
          libpulseaudio
          udev
          stdenv.cc.cc
          openssl
        ];

        # mkDefault: a host whose drivers lag behind (xps, nvidia) picks its own
        boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

        # Stable umu-launcher (1.4.0) can fail the SteamRT4 bootstrap's digest
        # validation, which breaks Battle.net. mkBefore: host overlays (xps's
        # nvidia-offload wrapper) then wrap this one via prev.
        nixpkgs.overlays = lib.mkBefore [
          (_final: _prev: { umu-launcher = pkgsUnstable.umu-launcher; })
        ];

        boot.kernel.sysctl."vm.max_map_count" = 2147483642;

        programs.nix-ld.enable = true;

        programs.gamemode.enable = true;

        programs.steam = {
          # mkDefault: a host can keep the rest of gaming without Steam (nomad)
          enable = lib.mkDefault true;
          # Not on roaming laptops: these open ports on every network joined
          remotePlay.openFirewall = !isLaptop;
          localNetworkGameTransfers.openFirewall = !isLaptop;
          gamescopeSession.enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };

        # Stable path for Prism instances: a /nix/store JavaPath breaks after GC
        environment.etc."jdk21".source = pkgs.jdk21;

        environment.systemPackages =
          with pkgs;
          [
            mangohud
            prismlauncher
            wineWow64Packages.stable
            winetricks
          ]
          ++ lib.optional config.gaming.boltLauncher bolt-launcher;

        # The GTNH Prism instance's launcher entry, alongside prismlauncher above,
        # and the GeForce NOW launcher for the Flatpak installed above
        home-manager.sharedModules =
          with inputs.self.modules.homeManager;
          [
            gtnhLauncher
            geforcenow
          ]
          ++ [
            inputs.battlenet-umu.homeModules.default
            ({ ... }: {
              programs.battlenet-umu.enable = true;
            })
          ];
      };
    };
}
