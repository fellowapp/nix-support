{pkgs}: {
  vitess = import ./vitess.nix {inherit pkgs;};

  debezium-connector-mysql = import ./debezium-connector-mysql.nix {inherit pkgs;};
  cursor-cli = import ./cursor-cli.nix {inherit pkgs;};
  elasticsearch8 = import ./elasticsearch8.nix {inherit pkgs;};
  atlas = import ./atlas.nix {inherit pkgs;};
  debezium-server = import ./debezium-server.nix {inherit pkgs;};
  svix-server = import ./svix-server.nix {inherit pkgs;};
  terragrunt = import ./terragrunt.nix {inherit pkgs;};
  debezium-connector-planetscale = import ./debezium-connector-planetscale.nix {inherit pkgs;};
  debezium-connector-vitess = import ./debezium-connector-vitess.nix {inherit pkgs;};
  rustfs = import ./rustfs.nix {inherit pkgs;};
}
