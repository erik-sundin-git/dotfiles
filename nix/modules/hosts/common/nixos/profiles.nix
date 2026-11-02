{ inputs, ... }:
let
  # Every profile owns erik, the overlays and the Home Manager wiring, and
  # forwards the NixOS-side systemConstants.system to HM, so a host only sets
  # `systemConstants.system.host`. Profile names must stay plain modules:
  # `install-host` on the live ISO scaffolds new hosts with `${type}Profile`.
  mkProfile =
    type: imports:
    { config, pkgsUnstable, ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          inputs.home-manager.nixosModules.home-manager
          nixpkgsOverlays
        ]
        ++ imports;
      systemConstants.system.type = type;

      users.users.erik = {
        isNormalUser = true;
        description = "erik";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      environment.systemPackages = [ pkgsUnstable.claude-code ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      # HM only activates users listed here; sharedModules alone creates none
      home-manager.users.erik = { };
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.commonHome
        { systemConstants.system = config.systemConstants.system; }
      ];
    };
in
{
  # A laptop without a window manager stack, for hosts that bring their own
  # (nomad is trying exwmStack)
  flake.modules.nixos.laptopBaseProfile = mkProfile "laptop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
      pulseaudio
    ]
  );

  flake.modules.nixos.laptopProfile = {
    imports = with inputs.self.modules.nixos; [
      laptopBaseProfile
      swayfxStack
    ];
  };

  # A desktop without a window manager stack, for hosts that bring their own
  # (forge uses i3Stack)
  flake.modules.nixos.desktopBaseProfile = mkProfile "desktop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
      pulseaudio
    ]
  );

  flake.modules.nixos.desktopProfile = {
    imports = with inputs.self.modules.nixos; [
      desktopBaseProfile
      swayfxStack
    ];
  };

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

  flake.modules.nixos.serverProfile =
    { ... }:
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

      systemd.sleep.settings.Sleep = {
        AllowSuspend = false;
        AllowHibernation = false;
        AllowSuspendThenHibernate = false;
      };

      programs.ssh.askPassword = "";

      documentation.nixos.enable = false;
    };
}
