{
  inputs,
  lib,
  config,
  ...
}:
{
  options.nas.nix = {
    enable = lib.mkEnableOption "management of unfree packages";
    allowUnfreePkgs = lib.mkOption {
      description = "List of unfree packages to allow";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) (config.nas.nix.allowUnfreePkgs);
    nix = lib.mkIf config.nas.nix.enable {
      gc.automatic = true;
      registry.nixpkgs.flake = inputs.nixpkgs;
    };
  };
}
