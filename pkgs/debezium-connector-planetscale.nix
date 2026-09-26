{pkgs}: let
  version = "2.4.0.Final";
  releaseTag = "v${version}.PS20241031.1";
in
  pkgs.stdenv.mkDerivation {
    pname = "debezium-connector-planetscale";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/planetscale/debezium-connector-planetscale-archived/releases/download/${releaseTag}/debezium-connector-planetscale-${version}-jar-with-dependencies.jar";
      sha256 = "14ns02flqwc93rrjqxrlsw46zi6skbdf4cw83pj82jgrh6xrqwm2";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/debezium/debezium-connector-planetscale
      cp $src $out/debezium/debezium-connector-planetscale/debezium-connector-planetscale-${version}-jar-with-dependencies.jar
    '';

    passthru.smokeTest = pkgs.writeShellScript "check-debezium-connector-planetscale" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.unzip pkgs.gnugrep]}:$PATH"
      exec ${pkgs.bash}/bin/bash ${../tests/debezium-connector.sh} "$1" "planetscale" "${version}"
    '';

    meta = with pkgs.lib; {
      description = "PlanetScale-compatible Debezium CDC connector for Vitess/Kafka Connect";
      homepage = "https://github.com/planetscale/debezium-connector-planetscale-archived";
      license = licenses.asl20;
      platforms = import ../nix/systems.nix;
    };
  }
