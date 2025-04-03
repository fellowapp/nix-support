{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "debezium";
  src = (
    fetchTarball {
      url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/3.0.8.Final/debezium-connector-mysql-3.0.8.Final-plugin.tar.gz";
      sha256 = "0mylvls3d8p1hx01kr0vd7mqaplxs98mhf0dp1i6zhhmzlaqf199";
    }
  );
  installPhase = ''
    mkdir -p $out/debezium/debezium-connector-mysql
    cp -R . $out/debezium/debezium-connector-mysql
  '';
}
