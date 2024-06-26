{ lib
, stdenvNoCC
, fetchFromGitHub
, gtk3
, hicolor-icon-theme
, jdupes
, boldPanelIcons ? false
, blackPanelIcons ? false
, alternativeIcons ? false
, themeVariants ? []
}:

let pname = "Whitesur-icon-theme";
in
lib.checkListOfEnum "${pname}: theme variants" [
  "default"
  "purple"
  "pink"
  "red"
  "orange"
  "yellow"
  "green"
  "grey"
  "nord"
  "all"
] themeVariants

stdenvNoCC.mkDerivation rec {
  inherit pname;
  version = "2024-06-25";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = pname;
    rev = "2c04cfdb6e18f2e5e4d6a0897b604c455f02e6a0";
    hash = "sha256-chAw4kWXl0THj5MifUn9g1Ix/YSA74+C4q1dg2+7/yU=";
  };

  nativeBuildInputs = [ gtk3 jdupes ];

  buildInputs = [ hicolor-icon-theme ];

  # These fixup steps are slow and unnecessary
  dontPatchELF = true;
  dontRewriteSymlinks = true;
  dontDropIconThemeCache = true;

  postPatch = ''
    patchShebangs install.sh
  '';

  installPhase = ''
    runHook preInstall

    ./install.sh --dest $out/share/icons \
      --name WhiteSur \
      --theme ${builtins.toString themeVariants} \
      ${lib.optionalString alternativeIcons "--alternative"} \
      ${lib.optionalString boldPanelIcons "--bold"} \
      ${lib.optionalString blackPanelIcons "--black"}

    jdupes --link-soft --recurse $out/share

    runHook postInstall
  '';

  meta = with lib; {
    description = "MacOS Big Sur style icon theme for Linux desktops";
    homepage = "https://github.com/vinceliuice/WhiteSur-icon-theme";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ icy-thought ];
  };

}
