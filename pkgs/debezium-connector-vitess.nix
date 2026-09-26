{pkgs}: let
  version = "2.4.1.Final";
in
  pkgs.stdenv.mkDerivation {
    pname = "debezium-connector-vitess";
    inherit version;

    src = builtins.fetchTarball {
      url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-vitess/${version}/debezium-connector-vitess-${version}-plugin.tar.gz";
      sha256 = "1zjjrgg3fyprym377maz40xl9pv1h8mgsfhc5alqm6v8xx0ilp72";
    };

    installPhase = ''
      mkdir -p $out/debezium/debezium-connector-vitess
      cp -R . $out/debezium/debezium-connector-vitess
    '';

    passthru.smokeTest = pkgs.writeShellScript "check-debezium-connector-vitess" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.unzip pkgs.gnugrep]}:$PATH"
      exec ${pkgs.bash}/bin/bash ${../tests/debezium-connector.sh} "$1" "vitess" "${version}"
    '';

    meta = {
      description = "Debezium change data capture connector for Vitess";
      homepage = "https://debezium.io/documentation/reference/stable/connectors/vitess.html";
      license = pkgs.lib.licenses.asl20;
      platforms = import ../nix/systems.nix;
    };
  }
