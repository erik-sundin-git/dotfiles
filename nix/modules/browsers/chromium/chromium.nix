{ ... }:
{
  flake.modules.homeManager.chromium =
    { pkgs, ... }:
    {
      programs.chromium = {
        enable = true;
        package = pkgs.ungoogled-chromium;

        # ungoogled-chromium ships with the Chrome Web Store disabled, so
        # policy-installed extensions won't fetch from Google's update server
        # out of the box. The chromium-web-store bootstrap below re-enables
        # CWS install/update flows for the rest of these IDs.
        extensions = [
          {
            id = "ocaahdebbfolfmndjeplogmgcagdmblk";
            updateUrl = "https://raw.githubusercontent.com/NeverDecaf/chromium-web-store/master/updates.xml";
          }

          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
          { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
          { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
          { id = "mdjildafknihdffpkfmmpnpoiajfjnjd"; } # Consent-O-Matic
          { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
          { id = "aleakchihdccplidncghkekgioiakgal"; } # h264ify
          # No CWS equivalent found for librewolf's lockedin-yt or besttimetracker.
        ];
      };
    };
}
