{pkgs}: let
  version = "2.3.5";
  platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";
  hashes = {
    darwin-amd64 = "sha256-/8/N3gDBS9Q8StfHG2IQ+/szcXuyNxI5jLLTbPbcph8=";
    darwin-arm64 = "sha256-rR43cKzLt+igWQaSKOrSK99vJ1kTEhJFG0T1GGYbjkA=";
    linux-amd64 = "sha256-xJ1MPgBM8VgboNSgDFAjom+E6y7BXV/odu7TbVND9GM=";
    linux-arm64 = "sha256-nOcPyB5QE56XdY739NxX6Vg+Tl7wWtdddTXDDKoWE4c=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "dolt";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/dolthub/dolt/releases/download/v${version}/dolt-${platform}-${arch}.tar.gz";
      hash = hashes."${platform}-${arch}";
    };
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/dolt $out/bin/dolt
      install -Dm644 LICENSES $out/share/licenses/dolt/LICENSES
      runHook postInstall
    '';
    meta = with pkgs.lib; {
      description = "MySQL-compatible database with Git-style version control";
      homepage = "https://www.dolthub.com/";
      changelog = "https://github.com/dolthub/dolt/releases/tag/v${version}";
      license = licenses.asl20;
      mainProgram = "dolt";
      platforms = ["aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"];
      sourceProvenance = [sourceTypes.binaryNativeCode];
    };
  }
