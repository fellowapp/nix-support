{pkgs}: {
  debezium-connector-mysql = import ./debezium-connector-mysql.nix {inherit pkgs;};
  cursor-cli = import ./cursor-cli.nix {inherit pkgs;};
  elasticsearch8 = import ./elasticsearch8.nix {inherit pkgs;};
  atlas = import ./atlas.nix {inherit pkgs;};
  debezium-server = import ./debezium-server.nix {inherit pkgs;};
  svix-server = import ./svix-server.nix {inherit pkgs;};
}
