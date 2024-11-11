{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  python,
  pythonOlder,

  # build-system
  setuptools,
  setuptools-scm,
  cython,
  py-cpuinfo,

  # dependencies
  numpy,

  # tests
  msgpack,
  pytestCheckHook,
  importlib-metadata,
}:

buildPythonPackage rec {
  pname = "numcodecs";
  version = "0.13.1";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-o883iB3wiY86nA1Ed9+IEz/oUYW//le6MbzC+iB3Cbw=";
  };

  build-system = [
    setuptools
    setuptools-scm
    cython
    py-cpuinfo
  ];

  dependencies = [ numpy ];

  optional-dependencies = {
    msgpack = [ msgpack ];
    # zfpy = [ zfpy ];
  };

  preBuild = lib.optionalString (stdenv.hostPlatform.isx86 && !stdenv.hostPlatform.avx2Support) ''
    export DISABLE_NUMCODECS_AVX2=1
  '';

  nativeCheckInputs = [
    pytestCheckHook
    msgpack
    importlib-metadata
  ];

  # not sure why
  # use if ... then ... else instead of lib.optionals, to prevent rebuild of generic packages
  disabledTests = if stdenv.hostPlatform.gcc.arch or null != null && !stdenv.hostPlatform.avx2Support
    then [ "test_encode_decode" "test_partial_decode" ] else null;

  # https://github.com/NixOS/nixpkgs/issues/255262
  pytestFlagsArray = [ "$out/${python.sitePackages}/numcodecs" ];

  meta = {
    homepage = "https://github.com/zarr-developers/numcodecs";
    license = lib.licenses.mit;
    description = "Buffer compression and transformation codecs for use in data storage and communication applications";
    maintainers = with lib.maintainers; [ doronbehar ];
  };
}
