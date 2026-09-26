{
  description = "A Nix flake providing easy access to useful packages that might not be available or up-to-date in the main nixpkgs repository.";

  inputs = {
    # Flox publishes against catalog pages from this mirror. flake.lock is the
    # shared pin for flake builds and Flox builds/publication.
    nixpkgs.url = "github:flox/nixpkgs?ref=unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem (import ./nix/systems.nix) (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: (pkg.pname or "") == "elasticsearch";
        };

        # Import our package modules
        customPkgs = import ./pkgs {inherit pkgs;};
      in {
        formatter = pkgs.alejandra;

        packages = {
          inherit
            (customPkgs)
            dolt
            cursor-cli
            elasticsearch8
            debezium-connector-mysql
            atlas
            debezium-server
            svix-server
            terragrunt
            debezium-connector-planetscale
            debezium-connector-vitess
            vitess
            rustfs
            ;
          debezium = customPkgs.debezium-connector-mysql; # Alias for compatibility
        };

        checks = {
          debezium-server = pkgs.runCommand "check-debezium-server" {} ''
            ${customPkgs.debezium-server.passthru.smokeTest} ${customPkgs.debezium-server}
            touch $out
          '';

          debezium-structure = pkgs.runCommand "check-debezium-connectors" {} ''
            ${customPkgs.debezium-connector-mysql.passthru.smokeTest} ${customPkgs.debezium-connector-mysql}
            ${customPkgs.debezium-connector-vitess.passthru.smokeTest} ${customPkgs.debezium-connector-vitess}
            ${customPkgs.debezium-connector-planetscale.passthru.smokeTest} ${customPkgs.debezium-connector-planetscale}
            touch $out
          '';

          elasticsearch-version = pkgs.runCommand "check-elasticsearch-version" {} ''
            ${customPkgs.elasticsearch8.passthru.smokeTest} ${customPkgs.elasticsearch8}
            touch $out
          '';

          vitess = pkgs.runCommand "check-vitess" {} ''
            ${customPkgs.vitess.passthru.smokeTest} ${customPkgs.vitess}
            touch $out
          '';

          atlas-version = pkgs.runCommand "check-atlas-version" {} ''
            ${customPkgs.atlas.passthru.smokeTest} ${customPkgs.atlas}
            touch $out
          '';
        };
      }
    );
}
