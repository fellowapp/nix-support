{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "debezium-connector-vitess";
  src = (
    fetchTarball {
      url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-vitess/2.4.1.Final/debezium-connector-vitess-2.4.1.Final-plugin.tar.gz";
      sha256 = "1zjjrgg3fyprym377maz40xl9pv1h8mgsfhc5alqm6v8xx0ilp72";
    }
  );
  installPhase = ''
    mkdir -p $out/debezium/debezium-connector-vitess
    cp -R . $out/debezium/debezium-connector-vitess
  '';
}
