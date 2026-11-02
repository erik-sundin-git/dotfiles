{ inputs, ... }:
{
  # The one overlay list, shared by every profile and the live ISO
  flake.modules.nixos.nixpkgsOverlays =
    { ... }:
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
        inputs.emacs-overlay.overlays.default
      ];
    };
}
