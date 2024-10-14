{ lib
, stdenv
, fetchFromGitLab
, cmake
, boost
, bzip2
, ffmpeg
, fftwSinglePrec
, hdf5
, muparser
, netcdf
, openssl
, python3
, qscintilla
, qtbase
, qtsvg
, qttools
, VideoDecodeAcceleration
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "ovito";
  version = "3.11.0";

  src = fetchFromGitLab {
    owner = "stuko";
    repo = "ovito";
    rev = "v${version}";
    hash = "sha256-egiA6z1e8ZS7i4CIVjsCKJP1wQSRpmSKitoVTszu0Mc=";
  };

  nativeBuildInputs = [
    cmake
    wrapQtAppsHook
  ];

  buildInputs = [
    boost
    bzip2
    ffmpeg
    fftwSinglePrec
    hdf5
    muparser
    netcdf
    openssl
    python3
    qscintilla
    qtbase
    qtsvg
    qttools
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    VideoDecodeAcceleration
  ];

  meta = with lib; {
    description = "Scientific visualization and analysis software for atomistic and particle simulation data";
    mainProgram = "ovito";
    homepage = "https://ovito.org";
    license = with licenses;  [ gpl3Only mit ];
    maintainers = with maintainers; [
      twhitehead
      chn
    ];
    broken = stdenv.hostPlatform.isDarwin; # clang-11: error: no such file or directory: '$-DOVITO_COPYRIGHT_NOTICE=...
  };
}
