{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  makeBinaryWrapper,
  nix-update-script,
  nixosTests,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  __structuredAttrs = true;

  pname = "cliproxyapi";
  version = "8.0.32";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-B2aUQ5vnO6mIFq0HF0zQH8pOUkr4/Sn+GbffReGB4nk=";
  };

  vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";

  subPackages = [ "cmd/server" ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
    "-X main.Commit=v${finalAttrs.version}"
    "-X main.BuildDate=1970-01-01"
  ];

  postInstall = ''
    mv $out/bin/server $out/bin/cliproxyapi
    mkdir -p $out/share/cliproxyapi
    cp ${finalAttrs.passthru.management} $out/share/cliproxyapi/management.html
    wrapProgram $out/bin/cliproxyapi \
      --set-default MANAGEMENT_STATIC_PATH "$out/share/cliproxyapi"
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru = {
    managementVersion = "1.26.5";
    management = fetchurl {
      url = "https://github.com/router-for-me/Cli-Proxy-API-Management-Center/releases/download/v${finalAttrs.passthru.managementVersion}/management.html";
      hash = "sha256-V1WM0CNHVnRjShFIJLAU0+WsFh9vN5Hj2Gtq2rlipwA=";
    };
    tests = { inherit (nixosTests) cliproxyapi; };
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Proxy that provides OpenAI/Gemini/Claude/Codex/Grok compatible API interfaces";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    changelog = "https://github.com/router-for-me/CLIProxyAPI/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ anish ];
    mainProgram = "cliproxyapi";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # for management
    ];
  };
})
