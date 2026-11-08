{ inputs, ... }:
let
  # Every profile owns erik, the overlays and the Home Manager wiring, and
  # forwards the NixOS-side systemConstants.system to HM, so a host only sets
  # `systemConstants.system.host`. Laptops and desktops add one WM stack.
  # install-host names these modules in generated hosts (flake.installer below).
  mkProfile =
    type: imports:
    {
      config,
      lib,
      pkgsUnstable,
      ...
    }:
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

      environment.systemPackages = [
        pkgsUnstable.claude-code
        pkgsUnstable.codex
      ]
      # A GUI app
      ++ lib.optional (type != "server") pkgsUnstable.chatgpt;

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
  flake.installer.profiles = {
    laptopBaseProfile = {
      type = "laptop";
      label = "Laptop";
      order = 10;
    };
    desktopBaseProfile = {
      type = "desktop";
      label = "Desktop";
      order = 20;
    };
    serverProfile = {
      type = "server";
      label = "Server (headless)";
      order = 30;
      stacks = false;
    };
    vmProfile = {
      type = "desktop";
      label = "VM (XFCE, qemu guest agents)";
      order = 40;
      stacks = false;
    };
  };

  # Without a window manager: the host imports one stack (stacks/*-stack.nix)
  flake.modules.nixos.laptopBaseProfile = mkProfile "laptop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
      pulseaudio
    ]
  );

  flake.modules.nixos.desktopBaseProfile = mkProfile "desktop" (
    with inputs.self.modules.nixos;
    [
      commonDesktop
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
