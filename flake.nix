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
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
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

          debezium-structure = pkgs.runCommand "check-debezium-structure" {} ''
            if [ ! -d ${customPkgs.debezium-connector-mysql}/debezium ]; then
              echo "✗ debezium folder does not exist in the package"
              exit 1
            fi
            touch $out
          '';

          elasticsearch-version = pkgs.runCommand "check-elasticsearch-version" {} ''
            output=$(${customPkgs.elasticsearch8}/bin/elasticsearch --version)
            expected_version="8.17.3"

            if echo "$output" | grep -q "$expected_version"; then
              echo "✓ Elasticsearch version check passed: $output"
              touch $out
            else
              echo "✗ Elasticsearch version check failed"
              echo "Expected version: $expected_version"
              echo "Actual output: $output"
              exit 1
            fi
          '';

          atlas-version = pkgs.runCommand "check-atlas-version" {} ''
            ${customPkgs.atlas.passthru.smokeTest} ${customPkgs.atlas}
            touch $out
          '';
        };
      }
    );
}
