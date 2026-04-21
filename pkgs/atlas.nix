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

  version = "1.2.0";

  hashes = {
    "amd64-linux" = "sha256-H9CQIf+hNXWUUF9EL5eDz8JZn6Wgq4UMWWLtbXe/nJo=";
    "arm64-linux" = "sha256-w3Xe5jnW1CllWJ7yhcFJ0XZJ+uEojIrBh4AUNWYfNUM=";
    "amd64-darwin" = "sha256-Nr2+Y7vCint0Anve/dUOwu8zrMYeo+H845s0He+NuOM=";
    "arm64-darwin" = "sha256-IFCP33rXl4neLUU68Lt3PiWCrLXJmV2hnhGel+yTb+E=";
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
