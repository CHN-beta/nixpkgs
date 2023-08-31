{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, level-zero, tbb_2021_8, libffi_3_3, zlib, ocl-icd }:

stdenv.mkDerivation rec {
  pname = "intel-oneapi-compiler";
  version = "2023.2.1";

  # Refer:
  # - https://archlinux.org/packages/extra/x86_64/intel-oneapi-compiler-shared-runtime
  # - https://archlinux.org/packages/extra/x86_64/intel-oneapi-compiler-dpcpp-cpp-runtime
  # intel-oneapi-compiler-shared-runtime has some files which need libsycl.so provided by intel-oneapi-compiler-dpcpp-cpp-runtime
  # intel-oneapi-compiler-dpcpp-cpp-runtime has some files which need many libraries provided by intel-oneapi-compiler-shared-runtime
  # so they are packaged together

  # to get all download links, use:
  # apt-cache depends --recurse intel-hpckit 2> /dev/null | grep -E "^intel-(hpckit|basekit|oneapi)" \
  #   | sort | xargs apt download --print-uris 2> /dev/null | awk '{print $1}' | sed "s/'\(.*\)'/\1/" | sort
  srcs =
    let
			debs =
			[
        "compiler-dpcpp-cpp-runtime-2023.2.1-2023.2.1-16_amd64"
        "compiler-dpcpp-cpp-common-2023.2.1-2023.2.1-16_all"
        "compiler-shared-runtime-2023.2.1-2023.2.1-16_amd64"
        "compiler-shared-common-2023.2.1-2023.2.1-16_all"
      ];
      hashes =
      [
        "0bwni8ypqnhbv7ld0adszc7x3lfkqnw57n1xjxc9qxc2i1h4s76r"
        "0kqmhgm5mkqab2ljc20c880s9zragkn0zn02rqg2wip4nwl0lmiv"
        "0p899rqq6dzgi67qsiyvn664xqb14vksdn1j6i0xaa45rq40ls7i"
        "0cjmb271ip9jj8fxpif16yhk94ifljjiwlim8xgd6v5za30sd2n8"
      ];
      packages = builtins.genList
        (i: { deb = builtins.elemAt debs i; hash = builtins.elemAt hashes i; })
        (builtins.length debs);
    in
      builtins.map
        (package: fetchurl
          {
            url = "https://apt.repos.intel.com/oneapi/pool/main/intel-onempi-${package.deb}.deb";
            sha256 = package.hash;
          }
        )
        packages;

  buildInputs = [
    dpkg
    autoPatchelfHook
  ];

  nativeBuildInputs = [
    stdenv.cc.cc.lib
    level-zero
    tbb_2021_8
    libffi_3_3
    zlib
    ocl-icd
  ];

  # llvm will provide lib/clang
  # ocl-icd will provide lib/libOpenCL.so*
  # ignore eclipse plugins
  installPhase = ''
    install -Dm644 opt/intel/oneapi/compiler/2023.1.0/documentation/en/man/common/man1/dpcpp.1 -t $out/share/man/man1
    install -d $out/share/cmake
    cp -r opt/intel/oneapi/compiler/2023.1.0/linux/{doc,IntelDPCPP,IntelSYCL} $out/share/cmake
    install -d $out/include
    cp -r opt/intel/oneapi/compiler/2023.1.0/linux/{include,compiler/{include,perf_headers/c++}}/* $out/include
    install -D opt/intel/oneapi/compiler/2023.1.0/linux/bin/* -t $out/bin
    cp -r opt/intel/oneapi/compiler/2023.1.0/linux/lib $out
    install -Dm644 opt/intel/oneapi/compiler/2023.1.0/linux/compiler/lib/intel64_lin/* -t $out/lib
    rm -r $out/lib/clang $out/lib/libOpenCL.so*
  '';

  dontStrip = true;

  meta = with lib; {
    description = "Intel oneAPI compiler runtime libraries";
    homepage = "https://software.intel.com/en-us/articles/opencl-drivers";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ Freed-Wu ];
  };
}