{pkgs}: let
  arch = with pkgs.stdenv.hostPlatform;
    if isx86_64
    then "amd64"
    else if isAarch64
    then "arm64"
    else throw "Unsupported architecture: ${pkgs.stdenv.hostPlatform.system}";
  plat =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else "linux";

  version = "0.32.1-d9ffec1-canary";

  hashes = {
    "amd64-linux" = "sha256-SgQy/Ht3PtSqqozZvJHlQKbydYX9r0ZQczCu8OQCV7M=";
    "arm64-linux" = "sha256-SgQy/Ht3PtSqqozZvJHlQKbydYX9r0ZQczCu8OQCV7M=";
    "amd64-darwin" = "sha256-9sse774dV4aLKMCvKGH6vJyguldsKPnhVN4KofywTMY=";
    "arm64-darwin" = "sha256-9sse774dV4aLKMCvKGH6vJyguldsKPnhVN4KofywTMY=";
    # Add other platform hashes as needed
  };
in
  pkgs.stdenv.mkDerivation rec {
    pname = "atlas";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://release.ariga.io/atlas/atlas-${plat}-${arch}-v${version}";
      hash = hashes."${arch}-${plat}";
      executable = true;
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/atlas
      chmod +x $out/bin/atlas
    '';

    meta = {
      description = "Atlas CLI - Manage your database schemas with Atlas";
      homepage = "https://atlasgo.io";
    };
  }
