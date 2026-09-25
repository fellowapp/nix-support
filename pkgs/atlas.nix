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

  source = builtins.fromJSON (builtins.readFile ./atlas.json);
  inherit (source) version hashes;
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
