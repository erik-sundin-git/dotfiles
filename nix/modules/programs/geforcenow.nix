{ ... }:
{
  flake.modules.nixos.geforcenow =
    { lib, pkgs, ... }:
    {
      services.flatpak.enable = true;

      # flatpak-session-helper starts with a nearly-empty PATH on NixOS, which
      # breaks `flatpak-spawn --host xdg-open` from inside the GFN sandbox —
      # login hangs because the OAuth URL never reaches the host browser (and
      # once xdg-open runs, it also needs to find the default browser binary,
      # which lives in the per-user profile).
      systemd.user.services.flatpak-session-helper.environment.PATH = lib.mkForce (
        lib.concatStringsSep ":" [
          "/etc/profiles/per-user/%u/bin"
          "%h/.nix-profile/bin"
          "/run/current-system/sw/bin"
          "${pkgs.systemd}/bin"
        ]
      );

      # Started by a timer, not multi-user.target: waiting for network-online
      # held graphical.target back ~4s on every boot.
      systemd.timers.geforce-now-install = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnBootSec = "2min";
      };

      systemd.services.geforce-now-install = {
        description = "Install and update the GeForce NOW Flatpak";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.flatpak ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 30;
        };
        script = ''
          flatpak remote-add --if-not-exists --from flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo
          flatpak remote-add --if-not-exists --from GeForceNOW \
            https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
          flatpak install --or-update --noninteractive --assumeyes \
            GeForceNOW com.nvidia.geforcenow
        '';
      };
    };

  flake.modules.homeManager.geforcenow =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.geforcenow ];
    };
}
