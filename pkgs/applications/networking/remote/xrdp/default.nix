{ lib, stdenv, fetchFromGitHub, applyPatches, pkg-config, which, perl, autoconf, automake, libtool, openssl, systemd, pam, fuse, libjpeg, libopus, nasm, xorg, variant ? null, nvidiaBusId ? null, fetchgit, mesa, libdrm }:

let
  version = "0.9.23.1";
  patchedXrdpSrc = applyPatches {
    patches = [ ./dynamic_config${lib.optionalString (variant == "nvidia") "_nvidia"}.patch ];
    name = "xrdp-patched-${version}";
    src = fetchFromGitHub
    (
      { owner = "neutrinolabs"; repo = "xrdp"; fetchSubmodules = true; }
      // (
        if variant == "nvidia" then
        {
          rev = "5ccabaf706cf860f692daae3927eeba4afbb8efb";
          hash = "sha256-hJnO1AQ+bSN2QaD3vLJssvLF/jPicU6zBjvFzD7HafU=";
        }
        else { rev = "v${version}"; hash = "sha256-fJKSEHB5X5QydKgRPjIMJzNaAy1EVJifHETSGmlJttQ="; }
      )
    );
  };

  xorgxrdp = stdenv.mkDerivation rec {
    pname = "xorgxrdp";
    version = "0.9.19";

    src = fetchFromGitHub
    (
      { owner = "neutrinolabs"; repo = "xorgxrdp"; }
      // (
        if variant == "nvidia" then
        {
          rev = "3d30c7a6ad4f4a582efcb919966d8f1508aa2d31";
          hash = "sha256-gs8y9ntEgCnFwFInB7vGHiOk0zLXwgL/qsPOAvYaHbY=";
        }
        else { rev = "v${version}"; hash = "sha256-WI1KyJDQkmNHwweZMbNd2KUfawaieoGMDMQfeD12cZs="; }
      )
    );

    nativeBuildInputs = [ pkg-config autoconf automake which libtool nasm ]
      ++ (lib.optionals (variant == "glamor") [ mesa ]);

    buildInputs = [ xorg.xorgserver ];

    postPatch = ''
      # patch from Debian, allows to run xrdp daemon under unprivileged user
      substituteInPlace module/rdpClientCon.c \
        --replace 'g_sck_listen(dev->listen_sck);' 'g_sck_listen(dev->listen_sck); g_chmod_hex(dev->uds_data, 0x0660);'

      substituteInPlace configure.ac \
        --replace 'moduledir=`pkg-config xorg-server --variable=moduledir`' "moduledir=$out/lib/xorg/modules" \
        --replace 'sysconfdir="/etc"' "sysconfdir=$out/etc"
    '' + (lib.optionalString (variant == "nvidia") ''
      sed -i 's|BusID ".*"|BusID "PCI:${nvidiaBusId}"|g' xrdpdev/xorg_nvidia.conf
    '');

    preConfigure = "./bootstrap";

    XRDP_CFLAGS = "-I${patchedXrdpSrc}/common"
      + lib.optionalString (variant == "glamor") " -I${libdrm.dev}/include/libdrm";
    configureFlags = lib.optionals (variant == "glamor") [ "--enable-glamor" ];

    enableParallelBuilding = true;
  };
  xrdp = stdenv.mkDerivation rec {
    inherit version;
    pname = "xrdp";

    src = patchedXrdpSrc;

    nativeBuildInputs = [ pkg-config autoconf automake which libtool nasm perl ];

    buildInputs = [ openssl systemd pam fuse libjpeg libopus xorg.libX11 xorg.libXfixes xorg.libXrandr ];

    postPatch =
      let file = "sesman${lib.optionalString (variant == "nvidia") "/sesexec"}/xauth.c";
      in ''substituteInPlace ${file} --replace "xauth -q" "${xorg.xauth}/bin/xauth -q"'';

    preConfigure = ''
      (cd librfxcodec && ./bootstrap && ./configure --prefix=$out --enable-static --disable-shared)
      ./bootstrap
    '';
    dontDisableStatic = true;
    configureFlags = [ "--with-systemdsystemunitdir=/var/empty" "--enable-ipv6" "--enable-jpeg" "--enable-fuse" "--enable-rfxcodec" "--enable-opus" "--enable-pam-config=unix" ];

    installFlags = [ "DESTDIR=$(out)" "prefix=" ];

    postInstall = ''
      # remove generated keys (as non-deterministic)
      rm $out/etc/xrdp/{rsakeys.ini,key.pem,cert.pem}

      cp $src/keygen/openssl.conf $out/share/xrdp/openssl.conf

      substituteInPlace $out/etc/xrdp/sesman.ini --replace /etc/xrdp/pulse $out/etc/xrdp/pulse

      # remove all session types except Xorg (they are not supported by this setup)
      perl -i -ne 'print unless /\[(X11rdp|Xvnc|console|vnc-any|sesman-any|rdp-any|neutrinordp-any)\]/ .. /^$/' $out/etc/xrdp/xrdp.ini

      # remove all session types and then add Xorg
      perl -i -ne 'print unless /\[(X11rdp|Xvnc|Xorg)\]/ .. /^$/' $out/etc/xrdp/sesman.ini

      cat >> $out/etc/xrdp/sesman.ini <<EOF

      [Xorg]
      param=${xorg.xorgserver}/bin/Xorg
      param=-modulepath
      param=${xorgxrdp}/lib/xorg/modules,${xorg.xorgserver}/lib/xorg/modules
      param=-config
      param=${xorgxrdp}/etc/X11/xrdp/xorg${lib.optionalString (variant == "nvidia") "_nvidia"}.conf
      param=-noreset
      param=-nolisten
      param=tcp
      param=-logfile
      param=.xorgxrdp.%s.log
      EOF
    '';

    enableParallelBuilding = true;

    meta = with lib; {
      description = "An open source RDP server";
      homepage = "https://github.com/neutrinolabs/xrdp";
      license = licenses.asl20;
      maintainers = with maintainers; [ chvp ];
      platforms = platforms.linux;
    };
  };
in xrdp
