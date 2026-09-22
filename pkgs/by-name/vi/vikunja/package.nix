{
  lib,
  fetchFromGitHub,
  stdenv,
  nodejs_24,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  buildGo127Module,
  mage,
  dart-sass,
  writableTmpDirAsHomeHook,
  writeShellScriptBin,
  nixosTests,
}:

let
  version = "2.6.0";
  # Fork of go-vikunja/vikunja carrying the hourly-granularity Gantt rewrite.
  # Bump with the rev below; the tree is upstream v${version} plus frontend changes.
  src = fetchFromGitHub {
    owner = "CHN-beta";
    repo = "vikunja";
    rev = "8de134cc6fd1bee9fc2adc71f8869c6670fc66a1";
    hash = "sha256-aigl9KT7Pj0gheT/oqd/HLQw2NkNN0wU8G6T1OR7V0c=";
  };

  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "vikunja-frontend";
    inherit version src;

    sourceRoot = "${finalAttrs.src.name}/frontend";

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs)
        pname
        version
        src
        sourceRoot
        ;
      pnpm = pnpm_11;
      fetcherVersion = 3;
      hash = "sha256-dINCE8NXzjafCPG1A9rDwOZzyA9fv5hYWmjpYI0VJQI=";
    };

    nativeBuildInputs = [
      nodejs_24
      dart-sass
      pnpmConfigHook
      pnpm_11
    ];

    postPatch = ''
      substituteInPlace src/version.json \
        --replace-fail '"dev"' '"${finalAttrs.version}"'
    '';

    doCheck = true;

    postBuild = ''
      # Force sass-embedded to use our dart-sass instead of bundled binaries.
      substituteInPlace node_modules/sass-embedded/dist/lib/src/compiler-path.js \
        --replace-fail 'compilerCommand = (() => {' 'compilerCommand = (() => { return ["${lib.getExe dart-sass}"];'
      pnpm run build
    '';

    checkPhase = ''
      runHook preCheck
      pnpm run test:unit --run
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist/ $out
      runHook postInstall
    '';
  });

  # Injects a `t.Skip()` into a given test since there's apparently no other way to skip tests here.
  skipTest =
    lineOffset: testCase: file:
    let
      jumpAndAppend = lib.concatStringsSep ";" (lib.replicate (lineOffset - 1) "n" ++ [ "a" ]);
    in
    ''
      sed -i -e '/${testCase}/{
      ${jumpAndAppend} t.Skip();
      }' ${file}
    '';
in
buildGo127Module {
  inherit src version;
  pname = "vikunja";

  nativeBuildInputs =
    let
      fakeGit = writeShellScriptBin "git" ''
        if [[ $@ = "describe --tags --always --abbrev=10" ]]; then
            echo "${version}"
        else
            >&2 echo "Unknown command: $@"
            exit 1
        fi
      '';
    in
    [
      fakeGit
      mage
      # mage wants to write some files to HOME
      writableTmpDirAsHomeHook
    ];

  vendorHash = "sha256-R6M5UyF10pIdoAvjWnS6Dqe/U6LTxmS6OwRTgmxfU4g=";

  inherit frontend;

  prePatch = ''
    cp -r ${frontend} frontend/dist
  '';

  postConfigure = ''
    # These tests need internet, so we skip them.
    ${skipTest 1 "TestConvertTrelloToVikunja" "pkg/modules/migration/trello/trello_test.go"}
    ${skipTest 1 "TestConvertTodoistToVikunja" "pkg/modules/migration/todoist/todoist_test.go"}
    # These tests require a full config with public URL and CORS enabled.
    ${skipTest 1 "TestCreateOrganizationMap" "pkg/modules/migration/trello/trello_test.go"}
    ${skipTest 1 "TestTaskAttachmentUploadSize" "pkg/webtests/task_attachment_upload_test.go"}
  '';

  buildPhase = ''
    runHook preBuild

    mage build:build

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mage test:feature
    mage test:web

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dt $out/bin vikunja

    runHook postInstall
  '';

  passthru = {
    tests.vikunja = nixosTests.vikunja;
    inherit frontend;
  };

  meta = {
    changelog = "https://github.com/go-vikunja/vikunja/blob/v${version}/CHANGELOG.md";
    description = "Todo-app to organize your life";
    homepage = "https://vikunja.io/";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [
      leona
      adamcstephens
    ];
    mainProgram = "vikunja";
    platforms = lib.platforms.linux;
  };
}
