{ lib
, stdenvNoCC
, fetchFromGitHub
, kdeclarative
, plasma-framework
, plasma-workspace
, gitUpdater
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "whitesur-kde";
  version = "unstable-2024-06-25";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = finalAttrs.pname;
    rev = "6705b5e2631128fda3af5baa475b276bb2780899";
    hash = "sha256-fsf6jApgF5NJSpP73cWJaFtCvWaRtF93DclV62Bu+xc=";
  };

  # Propagate sddm theme dependencies to user env otherwise sddm does
  # not find them. Putting them in buildInputs is not enough.
  propagatedUserEnvPkgs = [
    kdeclarative.bin
    plasma-framework
    plasma-workspace
  ];

  postPatch = ''
    patchShebangs install.sh

    substituteInPlace install.sh \
      --replace '$HOME/.config' $out/share \
      --replace '$HOME/.local' $out \
      --replace '"$HOME"/.Xresources' $out/doc/.Xresources

    substituteInPlace sddm/*/Main.qml \
      --replace /usr $out
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/doc

    name= ./install.sh

    mkdir -p $out/share/sddm/themes
    cp -a sddm/WhiteSur-6.0 $out/share/sddm/themes/WhiteSur

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "MacOS big sur like theme for KDE Plasma desktop";
    homepage = "https://github.com/vinceliuice/WhiteSur-kde";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = [ maintainers.romildo ];
  };
})
