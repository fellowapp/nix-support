{pkgs}: let
  version = "2.102.6";

  arch = with pkgs.stdenv.hostPlatform;
    if isx86_64
    then "amd64"
    else if isAarch64
    then "arm64"
    else throw "Unsupported architecture: ${system}";

  platform =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else if pkgs.stdenv.hostPlatform.isLinux
    then "linux"
    else throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}";

  hashes = {
    "darwin-amd64" = "sha256-nYKPWZ2yhB0kbMOaGG5izhqDkCMC4WNow9Xnitl+2TE=";
    "darwin-arm64" = "sha256-SJmr3kLuNHufbW2392K4xnOVw9EvIXv5ds+nmmIVe+U=";
    "linux-amd64" = "sha256-dmXUbhft0zQ/d6yoOVcrvx3TGFEyFSx9v0a7g/OSEYU=";
    "linux-arm64" = "sha256-vkVR+O2xge+t38E0yKxqZwhymimIgxgJIFBYEeJUeRs=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "depot";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/depot/cli/releases/download/v${version}/depot_${version}_${platform}_${arch}.tar.gz";
      hash = hashes."${platform}-${arch}";
    };

    installPhase = ''
      runHook preInstall

      install -Dm755 depot $out/bin/depot

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "CLI for building Docker images with Depot";
      homepage = "https://depot.dev";
      changelog = "https://github.com/depot/cli/releases/tag/v${version}";
      license = licenses.mit;
      mainProgram = "depot";
      platforms = platforms.linux ++ platforms.darwin;
    };
  }
