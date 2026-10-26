{ inputs, ... }:
let
  # Every profile pulls in Home Manager for erik and forwards the NixOS-side
  # systemConstants.system to HM, so a host only sets `systemConstants.system.host`.
  # `install-host` on the live ISO scaffolds new hosts on top of these.
  mkProfile =
    type: imports:
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ] ++ imports;
      systemConstants.system.type = type;
      # HM only activates users listed here; sharedModules alone creates none
      home-manager.users.erik = { };
      home-manager.sharedModules = [
        { systemConstants.system = config.systemConstants.system; }
      ];
    };
in
{
  flake.modules.nixos.laptopProfile = mkProfile "laptop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
      swayfxStack
      pulseaudio
    ]
  );

  flake.modules.nixos.desktopProfile = mkProfile "desktop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
      swayfxStack
      pulseaudio
    ]
  );

  flake.modules.nixos.vmProfile =
    { ... }:
    {
      imports = [
        (mkProfile "desktop" (
          with inputs.self.modules.nixos;
          [
            xfceStack
            commonDesktop
            pulseaudio
          ]
        ))
      ];

      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;
    };

  # Headless: no commonDesktop, so the user, overlays and HM wiring that it
  # normally provides are set here.
  flake.modules.nixos.serverProfile =
    { pkgsUnstable, ... }:
    {
      imports = [
        (mkProfile "server" (
          with inputs.self.modules.nixos;
          [
            commonConfig
            memory
          ]
        ))
      ];

      services.logind.settings.Login.HandleLidSwitch = "ignore";
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

      systemd.sleep.extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowSuspendThenHibernate=no
      '';

      programs.ssh.askPassword = "";

      environment.systemPackages = [ pkgsUnstable.claude-code ];

      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
      ];

      users.users.erik = {
        isNormalUser = true;
        description = "erik";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = with inputs.self.modules.homeManager; [ commonHome ];
    };
}
