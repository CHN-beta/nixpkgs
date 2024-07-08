{
  cudaVersion,
  lib,
  nvccCompatibilities,
  pkgs,
  stdenv,
  stdenvAdapters,

  config,
  enableCcache ? config.enableCcache, # or false,
  ccacheStdenv ? null,
}:

let
  gccMajorVersion = nvccCompatibilities.${cudaVersion}.gccMaxMajorVersion;
  originalStdenv = pkgs."gcc${gccMajorVersion}Stdenv";
  stdenvWithCcache = if enableCcache then ccacheStdenv.override { stdenv = originalStdenv; } else originalStdenv;
  cudaStdenv = stdenvAdapters.useLibsFrom stdenv stdenvWithCcache;
  passthruExtra = {
    # cudaPackages.backendStdenv.nixpkgsCompatibleLibstdcxx has been removed,
    # if you need it you're likely doing something wrong. There has been a
    # warning here for a month or so. Now we can no longer return any
    # meaningful value in its place and drop the attribute entirely.
  };
  assertCondition = true;
in

# TODO: Consider testing whether we in fact use the newer libstdc++

lib.extendDerivation assertCondition passthruExtra cudaStdenv
