{pkgs}: let
  version = "3.0.8.Final";
in
  pkgs.stdenv.mkDerivation {
    pname = "debezium-connector-mysql";
    inherit version;

    src = builtins.fetchTarball {
      url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/${version}/debezium-connector-mysql-${version}-plugin.tar.gz";
      sha256 = "0mylvls3d8p1hx01kr0vd7mqaplxs98mhf0dp1i6zhhmzlaqf199";
    };

    installPhase = ''
      mkdir -p $out/debezium/debezium-connector-mysql
      cp -R . $out/debezium/debezium-connector-mysql
    '';

    passthru.smokeTest = pkgs.writeShellScript "check-debezium-connector-mysql" ''
      export PATH="${pkgs.lib.makeBinPath [pkgs.unzip pkgs.gnugrep]}:$PATH"
      exec ${pkgs.bash}/bin/bash ${../tests/debezium-connector.sh} "$1" "mysql" "${version}"
    '';

    meta = {
      description = "Debezium change data capture connector for MySQL";
      homepage = "https://debezium.io/documentation/reference/stable/connectors/mysql.html";
      license = pkgs.lib.licenses.asl20;
      platforms = import ../nix/systems.nix;
    };
  }
