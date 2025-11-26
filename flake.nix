{
  description = "A Nix flake providing easy access to useful packages that might not be available or up-to-date in the main nixpkgs repository.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
        packages = {
          inherit
            (customPkgs)
            cursor-cli
            elasticsearch8
            debezium-connector-mysql
            atlas
            debezium-server
            svix-server
            ;
          debezium = customPkgs.debezium-connector-mysql; # Alias for compatibility
        };

        checks = {
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
            output=$(${customPkgs.atlas}/bin/atlas version)
            expected_version="0.32.1"

            if echo "$output" | grep -q "$expected_version"; then
              echo "✓ Atlas version check passed: $output"
              touch $out
            else
              echo "✗ Atlas version check failed"
              echo "Expected version: $expected_version"
              echo "Actual output: $output"
              exit 1
            fi
          '';
        };
      }
    );
}
