{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, Security
, autoreconfHook
, util-linux
, openssl
, cacert
# The primary --enable-XXX variant. 'all' enables most features, but causes build-errors for some software,
# requiring to build a special variant for that software. Example: 'haproxy'
, variant ? "all"
, extraConfigureFlags ? []
, enableLto ? !(stdenv.isDarwin || stdenv.hostPlatform.isStatic || stdenv.cc.isClang)
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wolfssl-${variant}";
  version = "5.6.6";

  src = fetchFromGitHub {
    owner = "wolfSSL";
    repo = "wolfssl";
    rev = "refs/tags/v${finalAttrs.version}-stable";
    hash = "sha256-HXl8GgngC1J8Dlt7fXBrVRa+IV7thVr+MIpeuf3Khcg=";
  };

  patches = [
    (fetchpatch {
      name = "CVE-2024-0901.patch";
      url = "https://github.com/wolfSSL/wolfssl/commit/9db20774d8abe0725734d48090bd4f650a477b8a.patch";
      hash = "sha256-tO0fVBtEuvoJLUgDwjz3otk4yj1txASXEt0c0Rf9g3Q=";
    })
    # simply adds an optional rowhammer-resistant mode for RSA decryption,
    # *not enabled by default*
    (fetchpatch {
      name = "CVE-2024-1545.patch";
      url = "https://github.com/wolfSSL/wolfssl/commit/de4a6f9e00f6fbcaa7e20ed7bd89b5d50179e634.patch";
      hash = "sha256-6DctT4GSBDqVeON9QsTsxVXTLD20zE64uUxGTZZFl5M=";
    })
    # CVE-2024-1545, but for eddsa
    (fetchpatch {
      name = "eddsa-check-priv.patch";
      url = "https://github.com/wolfSSL/wolfssl/commit/c8d0bb0bd8fcd3dd177ec04e9a659a006df51b73.patch";
      hash = "sha256-YlGBilR1pgH7BVuvL/liwOtgx/f+1troyV9Rl6Ftkr4=";
    })
  ];

  postPatch = ''
    patchShebangs ./scripts
    # ocsp stapling tests require network access, so skip them
    sed -i -e'2s/.*/exit 77/' scripts/ocsp-stapling.test
    # ensure test detects musl-based systems too
    substituteInPlace scripts/ocsp-stapling2.test \
      --replace '"linux-gnu"' '"linux-"'
  '';

  configureFlags = [
    "--enable-${variant}"
    "--enable-reproducible-build"
  ] ++ lib.optionals (variant == "all") [
    # Extra feature flags to add while building the 'all' variant.
    # Since they conflict while building other variants, only specify them for this one.
    "--enable-pkcs11"
    "--enable-writedup"
    "--enable-base64encode"
  ] ++ [
    # We're not on tiny embedded machines.
    # Increase TLS session cache from 33 sessions to 20k.
    "--enable-bigcache"

    # Use WolfSSL's Single Precision Math with timing-resistant cryptography.
    "--enable-sp=yes${lib.optionalString (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch) ",asm"}"
    "--enable-sp-math-all"
    "--enable-harden"
  ] ++ lib.optionals (stdenv.hostPlatform.isx86_64) [
    # Enable AVX/AVX2/AES-NI instructions, gated by runtime detection via CPUID.
    "--enable-intelasm"
    "--enable-aesni"
  ] ++ lib.optionals (stdenv.isAarch64 && stdenv.isDarwin) [
    # No runtime detection under ARM and no platform function checks like for X86.
    # However, all ARM macOS systems have the supported extensions autodetected in the configure script.
    "--enable-armasm=inline"
  ] ++ extraConfigureFlags;

  # LTO should help with the C implementations.
  env.NIX_CFLAGS_COMPILE = lib.optionalString enableLto "-flto";
  env.NIX_LDFLAGS_COMPILE = lib.optionalString enableLto "-flto";

  outputs = [
    "dev"
    "doc"
    "lib"
    "out"
  ];

  propagatedBuildInputs = lib.optionals stdenv.isDarwin [
    Security
  ];

  nativeBuildInputs = [
    autoreconfHook
    util-linux
  ];

  doCheck = true;

  nativeCheckInputs = [
    openssl
    cacert
  ];

  postInstall = ''
    # fix recursive cycle:
    # wolfssl-config points to dev, dev propagates bin
    moveToOutput bin/wolfssl-config "$dev"
    # moveToOutput also removes "$out" so recreate it
    mkdir -p "$out"
  '';

  meta = with lib; {
    description = "A small, fast, portable implementation of TLS/SSL for embedded devices";
    homepage = "https://www.wolfssl.com/";
    changelog = "https://github.com/wolfSSL/wolfssl/releases/tag/v${finalAttrs.version}-stable";
    platforms = platforms.all;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ fab vifino ];
  };
})
