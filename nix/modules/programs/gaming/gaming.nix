{ inputs, ... }:
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.geforcenow ];

      programs.nix-ld.libraries = with pkgs; [
        libGL
        mesa
        xorg.libX11
        xorg.libXrandr
        xorg.libXcursor
        xorg.libXi
        xorg.libXext
        xorg.libXtst
        xorg.libXxf86vm
        libpulseaudio
        udev
        stdenv.cc.cc
        openssl
      ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.kernel.sysctl."vm.max_map_count" = 2147483642;

      programs.nix-ld.enable = true;

      programs.gamemode.enable = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      environment.systemPackages = with pkgs; [
        mangohud
        protonup-qt
        bolt-launcher
        jdk
        prismlauncher
      ];
    };
}
