{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { ... }:
      {
        imports = [
          inputs.preservation.nixosModules.default
        ];

        # Change after first login with: passwd
        users.users.erik.initialPassword = "12345";

        preservation = {
          enable = true;

          preserveAt."/persistent" = {
            directories = [
              "/var/log"
              {
                directory = "/var/lib/nixos";
                inInitrd = true;
              }
              "/var/lib/bluetooth"
              "/var/lib/systemd/coredump"
              {
                directory = "/var/lib/libvirtd";
                user = "root";
                group = "root";
                mode = "0711";
              }
              {
                directory = "/etc/NetworkManager/system-connections";
                mode = "0700";
              }
              # SSH host keys — persisting the whole dir avoids parentDirectory issues.
              # If NixOS activation conflicts with sshd_config here, switch to
              # individual key files instead.
              {
                directory = "/etc/ssh";
                mode = "0755";
              }
            ];

            files = [
              {
                file = "/etc/machine-id";
                inInitrd = true;
              }
            ];

            users.erik = {
              directories = [
                {
                  directory = ".ssh";
                  mode = "0700";
                }
                {
                  directory = ".gnupg";
                  mode = "0700";
                }
                ".local/share/keyrings"
                "dotfiles"
                "Downloads"
                "Documents"
                "Pictures"
                "Videos"
                "Music"
                ".config/chromium"
                ".mozilla"
                ".local/share/notmuch"
                ".emacs.d/.local"
                ".config/protonmail"
                ".config/Beeper"
                ".config/vlc"
              ];
            };
          };
        };
      };
  };
}
