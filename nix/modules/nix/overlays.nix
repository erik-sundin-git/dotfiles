{ inputs, ... }:
{
  # The one overlay list (and nixpkgs config), shared by every profile and
  # the live ISO
  flake.modules.nixos.nixpkgsOverlays =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
        inputs.emacs-overlay.overlays.default
      ];
    };
}
