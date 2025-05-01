{pkgs}: {
  debezium-connector-mysql = import ./debezium-connector-mysql.nix {inherit pkgs;};
  elasticsearch8 = import ./elasticsearch8.nix {inherit pkgs;};
  atlas = import ./atlas.nix {inherit pkgs;};
}
