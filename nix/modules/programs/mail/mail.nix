# Proton Mail in Emacs: Proton Mail Bridge (local IMAP/SMTP) -> mbsync
# (~/Mail/proton) -> notmuch -> notmuch.el, sending through msmtp.
# The other files in this directory add to the same homeModule. Imported per
# host, because Bridge needs an interactive login on each machine (see the
# Mail section in CLAUDE.md for the one-time steps).
{ inputs, ... }:
{
  flake.installer.homeModules.mail = {
    label = "Proton Mail (Bridge + mbsync + notmuch)";
    order = 30;
  };

  flake.modules.homeManager.mail =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      address = "mail@eriksundin.com";
      # Bridge keeps its self-signed cert (CN/IP SAN 127.0.0.1) in its vault;
      # `cert export` in `protonmail-bridge --cli` writes it here. A string,
      # so it stays out of the store.
      certFile = "${config.xdg.configHome}/protonmail/bridge-v3/cert.pem";
      tls = {
        enable = true;
        useStartTls = true;
        certificatesFile = certFile;
      };
    in
    {
      options.mailSync.stage = lib.mkOption {
        type = lib.types.ints.between 1 5;
        default = 1;
        description = ''
          Rollout stage of the Proton sync, raised by hand once the previous
          one has been checked against the web app:
          1 = pull only, 2 = + push read/flag state, 3 = + push moves
          (mail-move: deleted -> Trash, archived -> Archive) without expunging
          on Proton, 4 = + expunge on Proton, 5 = + spam -> Spam.
        '';
      };

      config = {
        accounts.email.maildirBasePath = "Mail";
        accounts.email.accounts.proton = {
          primary = true;
          inherit address;
          # Combined address mode: every address of the Proton account arrives
          # here and can be sent from. Listed so notmuch replies from the right
          # one and msmtp accepts them as From. Private, so git-crypt encrypted.
          inherit (import "${inputs.self}/nix/secrets/mail.nix") aliases;
          realName = "Erik Sundin";
          userName = address;
          # The bridge password (from `info` in the Bridge CLI), stored once per
          # host with: secret-tool store --label="Proton Bridge" service protonmail-bridge user <address>
          passwordCommand = [
            "${pkgs.libsecret}/bin/secret-tool"
            "lookup"
            "service"
            "protonmail-bridge"
            "user"
            address
          ];
          # Must be 127.0.0.1, not localhost: the cert has no DNS name.
          imap = {
            host = "127.0.0.1";
            port = 1143;
            inherit tls;
          };
          smtp = {
            host = "127.0.0.1";
            port = 1025;
            inherit tls;
          };
          folders = {
            inbox = "INBOX";
            sent = "Sent";
            drafts = "Drafts";
            trash = "Trash";
          };
        };

        home.packages = [ pkgs.libsecret ];
      };
    };
}
