{pkgs}: let
  arch = with pkgs.stdenv.hostPlatform;
    if isx86_64
    then "x86_64"
    else if isAarch64
    then "aarch64"
    else throw "Unsupported architecture: ${pkgs.stdenv.hostPlatform.system}";
  plat =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else "linux";
  hashes = {
    "x86_64-linux" = "sha512-au9PyE67/JjmZiQYxzTqicro5TqNbB+9U1KAe8Qn4EDmK+VotQKr3Ot6L1dTTq5g4xcS0Fg9N1L9Obe4o2MtOw==";
    "aarch64-linux" = "sha512-Cxs+oOtrNy+4LN83YXGYmpMGi9xMP4DcJnB0g9CWBfa0DGUJbOzF4Vz87ZxvgjU/SmMutnesXXWbM4Pfk3bMRg==";
    "x86_64-darwin" = "sha512-R7YbSehFAGJLwrSx6FNs6CArYUyo1JZc4VKZQJ5fbDVBpyhwFmtI6PWSVlLYyx2qnj9Yd/7YBTuhrj9sqQDYZQ==";
    "aarch64-darwin" = "sha512-R7YbSehFAGJLwrSx6FNs6CArYUyo1JZc4VKZQJ5fbDVBpyhwFmtI6PWSVlLYyx2qnj9Yd/7YBTuhrj9sqQDYZQ==";
  };
in
  pkgs.stdenv.mkDerivation rec {
    pname = "elasticsearch";
    version = "8.17.3";

    src = pkgs.fetchurl {
      url = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${version}-${plat}-${arch}.tar.gz";
      hash = hashes."${arch}-${plat}";
    };

    postPatch = ''
      substituteInPlace bin/elasticsearch-env --replace \
        "ES_CLASSPATH=\"\$ES_HOME/lib/*\"" \
        "ES_CLASSPATH=\"$out/lib/*\""
      substituteInPlace bin/elasticsearch-cli --replace \
        "ES_CLASSPATH=\"\$ES_CLASSPATH:\$ES_HOME/\$additional_classpath_directory/*\"" \
        "ES_CLASSPATH=\"\$ES_CLASSPATH:$out/\$additional_classpath_directory/*\""
    '';

    nativeBuildInputs = [
      pkgs.makeBinaryWrapper
    ] ++ pkgs.lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      pkgs.patchelf
    ];

    buildInputs = [
      pkgs.jre_headless
      pkgs.util-linux
      pkgs.zlib
    ];

    runtimeDependencies = [pkgs.zlib];

    installPhase = ''
      mkdir -p $out
      cp -R bin config lib modules plugins $out
      chmod +x $out/bin/*
      substituteInPlace $out/bin/elasticsearch \
        --replace 'bin/elasticsearch-keystore' "$out/bin/elasticsearch-keystore"
      wrapProgram $out/bin/elasticsearch \
        --prefix PATH : "${
        pkgs.lib.strings.makeBinPath [
          pkgs.util-linuxMinimal
          pkgs.coreutils
          pkgs.gnugrep
        ]
      }" \
        --set ES_JAVA_HOME "${pkgs.jre_headless}"
      wrapProgram $out/bin/elasticsearch-plugin --set ES_JAVA_HOME "${pkgs.jre_headless}"
    '';

    postInstall = pkgs.lib.optionalString (!pkgs.stdenv.hostPlatform.isDarwin) ''
      # Manually patch ELF binaries on Linux to fix dynamic library paths
      find $out -type f -executable | while read -r file; do
        if file "$file" | grep -q "ELF.*executable" && [ ! -L "$file" ]; then
          echo "Patching ELF executable: $file"
          # Use patchelf to set the interpreter and fix rpath, but be more conservative
          if ${pkgs.patchelf}/bin/patchelf --print-interpreter "$file" 2>/dev/null; then
            ${pkgs.patchelf}/bin/patchelf \
              --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
              "$file" 2>/dev/null || echo "Failed to set interpreter for $file"
          fi
          if ${pkgs.patchelf}/bin/patchelf --print-rpath "$file" 2>/dev/null; then
            ${pkgs.patchelf}/bin/patchelf \
              --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib pkgs.stdenv.cc.cc.lib ]}" \
              "$file" 2>/dev/null || echo "Failed to set rpath for $file"
          fi
        fi
      done

      # Also patch any shared libraries, but be selective
      find $out -name "*.so*" -type f | while read -r file; do
        if file "$file" | grep -q "ELF.*shared object" && [ ! -L "$file" ]; then
          echo "Patching shared library: $file"
          ${pkgs.patchelf}/bin/patchelf \
            --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib pkgs.stdenv.cc.cc.lib ]}" \
            "$file" 2>/dev/null || echo "Failed to patch shared library $file"
        fi
      done
    '';

    passthru = {
      enableUnfree = true;
    };
  }
