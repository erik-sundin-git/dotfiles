{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
        ];

        fileSystems."/nix".neededForBoot = true;
        fileSystems."/persistent".neededForBoot = true;

        disko.devices = {
          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=8G"
              "mode=755"
            ];
          };

          disk.main = {
            # nomad's NVMe — update this if the disk shows up under a different name
            device = "/dev/nvme0n1";
            type = "disk";

            content = {
              type = "gpt";

              partitions = {
                esp = {
                  size = "512M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [
                      "fmask=0077"
                      "dmask=0077"
                    ];
                  };
                };

                swap = {
                  size = "16G";
                  content = {
                    type = "swap";
                    resumeDevice = true;
                  };
                };

                root = {
                  size = "100%";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "/nix" = {
                        mountOptions = [
                          "subvol=nix"
                          "compress=zstd"
                          "noatime"
                        ];
                        mountpoint = "/nix";
                      };
                      "/persistent" = {
                        mountOptions = [
                          "subvol=persistent"
                          "compress=zstd"
                          "noatime"
                        ];
                        mountpoint = "/persistent";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
  };
}
