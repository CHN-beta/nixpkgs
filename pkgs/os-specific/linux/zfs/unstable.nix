{ callPackage
, kernel ? null
, stdenv
, linuxKernel
, nixosTests
, ...
} @ args:

let
  stdenv' = if kernel == null then stdenv else kernel.stdenv;
in
callPackage ./generic.nix args {
  # You have to ensure that in `pkgs/top-level/linux-kernels.nix`
  # this attribute is the correct one for this package.
  kernelModuleAttribute = "zfsUnstable";

  # check the release notes for compatible kernels
  kernelCompatible = kernel.kernelOlder "6.9";

  latestCompatibleLinuxPackages = linuxKernel.packages.linux_6_6;

  # this package should point to a version / git revision compatible with the latest kernel release
  # IMPORTANT: Always use a tagged release candidate or commits from the
  # zfs-<version>-staging branch, because this is tested by the OpenZFS
  # maintainers.
  version = "2.2.2";

  isUnstable = true;
  tests = [
    nixosTests.zfs.unstable
  ];

  hash = "sha256-CqhETAwhWMhbld5ib3Rz1dxms+GQbLwjEZw/V7U/2nE=";
}
