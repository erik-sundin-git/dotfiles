{
  flake.modules.nixos.linux-desktop = {
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/356ea0bd-3de0-47e6-8200-f5ab07cc296d";
      fsType = "ext4";
    };

    swapDevices = [
      { device = "/dev/disk/by-uuid/6ad31753-3de0-405a-a362-3c620a4daf23"; }
    ];
  };
}
