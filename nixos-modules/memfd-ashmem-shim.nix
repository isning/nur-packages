{ config, lib, pkgs, ... }:

let
  cfg = config.boot.memfd-ashmem-shim;
  
  shimPackage = config.boot.kernelPackages.callPackage ../pkgs/memfd-ashmem-shim { };
in
{
  options.boot.memfd-ashmem-shim = {
    enable = lib.mkEnableOption "memfd ashmem shim OOT kernel module";
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ shimPackage ];

    boot.kernelModules = [ "memfd_ashmem_shim" ];
  };
}