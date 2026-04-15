{
  inputs,
  config,
  ...
}:
let
  home-manager-config =
    { lib, ... }:
    {
      home-manager = {
        verbose = true;
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        backupCommand = "rm";
        overwriteBackup = true;
      };
    };
in
{
  flake.modules.nixos.home-manager = {
    _module.args = {
      inherit inputs;
    };
    imports = [
      inputs.home-manager.nixosModules.home-manager
      home-manager-config
    ];
  };

}
