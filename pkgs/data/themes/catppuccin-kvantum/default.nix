{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  accent ? "blue",
  variant ? "frappe",
}: let
  pname = "catppuccin-kvantum";
in
  lib.checkListOfEnum "${pname}: theme accent" ["blue" "flamingo" "green" "lavender" "maroon" "mauve" "peach" "pink" "red" "rosewater" "sapphire" "sky" "teal" "yellow"] [accent]
  lib.checkListOfEnum "${pname}: color variant" ["latte" "frappe" "macchiato" "mocha"] [variant]

  stdenvNoCC.mkDerivation {
    inherit pname;
    version = "unstable-2024-06-19";

    src = fetchFromGitHub {
      owner = "catppuccin";
      repo = "Kvantum";
      rev = "c8538166447e595d3ebcd508699a8fed2d24d75f";
      sha256 = "sha256-Ubj+dydyS36QotO7YAnZFnMANogscDwZ0ryIsQg0L48=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/Kvantum
      cp -a $src/themes/catppuccin-${variant}-${accent} $out/share/Kvantum
      runHook postInstall
    '';

    meta = with lib; {
      description = "Soothing pastel theme for Kvantum";
      homepage = "https://github.com/catppuccin/Kvantum";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ bastaynav ];
    };
  }
