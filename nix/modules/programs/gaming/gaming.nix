{ inputs, ... }:
{
  flake.installer.features.gaming = {
    label = "Gaming: Steam, latest kernel, GeForce NOW, Prism";
    order = 10;
  };

  flake.modules.nixos.gaming =
    { config, pkgs, ... }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      imports = [ inputs.self.modules.nixos.geforcenow ];

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

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.kernel.sysctl."vm.max_map_count" = 2147483642;

      programs.nix-ld.enable = true;

      programs.gamemode.enable = true;

      programs.steam = {
        enable = true;
        # Not on roaming laptops: these open ports on every network joined
        remotePlay.openFirewall = !isLaptop;
        localNetworkGameTransfers.openFirewall = !isLaptop;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      # Stable path for Prism instances: a /nix/store JavaPath breaks after GC
      environment.etc."jdk21".source = pkgs.jdk21;

      environment.systemPackages = with pkgs; [
        mangohud
        bolt-launcher
        prismlauncher
        wineWow64Packages.stable
        winetricks
      ];

      # The GTNH Prism instance's launcher entry, alongside prismlauncher above,
      # and the GeForce NOW launcher for the Flatpak installed above
      home-manager.sharedModules = with inputs.self.modules.homeManager; [
        gtnhLauncher
        geforcenow
      ];
    };
}
