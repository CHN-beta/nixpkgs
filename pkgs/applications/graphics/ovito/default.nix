{ lib
, stdenv
, fetchFromGitLab
, fetchurl
, makeDesktopItem
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
# needed to run natively on wayland
, qtwayland
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
    qtwayland
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    VideoDecodeAcceleration
  ];

  # manually create a desktop file
  postInstall =
    let
      icon = fetchurl {
        url = "https://www.ovito.org/wp-content/uploads/logo_rgb-768x737.png";
        sha256 = "1wp9c61cdw1bis4ykn8sdi3mr2ah6jl3bl5bil6fx6yywm8qis8l";
      };
      desktopFile = makeDesktopItem {
        name = pname;
        comment= "Open Visualization Tool";
        exec = "@out@/bin/ovito";
        inherit icon;
        terminal = false;
        startupNotify = false;
        desktopName = "ovito";
        startupWMClass = "Ovito";
        categories = [ "Science" ];
      };
    in ''
      mkdir -p $out/share/applications
      substituteAll ${desktopFile}/share/applications/${pname}.desktop $out/share/applications/${pname}.desktop
    '';

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
