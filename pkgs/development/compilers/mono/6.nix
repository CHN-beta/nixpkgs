{ callPackage, Foundation, libobjc }:

callPackage ./generic.nix ({
  inherit Foundation libobjc;
  version = "6.12.0.198";
  srcArchiveSuffix = "tar.xz";
  sha256 = "sha256-EFLcfGUWNpRaLpJ1a0kgFAF1aRa+UTQxaLupxqUdDew=";
  enableParallelBuilding = true;
  sourceSubdir = "preview/";
})
