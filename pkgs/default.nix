{pkgs}: {
  debezium = import ./debezium.nix {inherit pkgs;};
  elasticsearch8 = import ./elasticsearch8.nix {inherit pkgs;};
  atlas = import ./atlas.nix {inherit pkgs;};
}
