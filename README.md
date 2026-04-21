# nix-support

A Nix flake providing easy access to useful packages that might not be available
or up-to-date in the main nixpkgs repository.

## Currently Supported Packages

| Package | Version | Description |
| --- | --- | --- |
| `atlas` | 1.2.0 | Atlas CLI tool for database schema management, with support for both x86_64 and aarch64 architectures on Linux and macOS |
| `cursor-cli` | latest | [Cursor CLI tool](https://cursor.com/cli) (cluster-agent) |
| `debezium-connector-mysql` | 3.0.8.Final | Debezium's change data capture (CDC) connector for MySQL databases (also exposed as `debezium`) |
| `debezium-connector-planetscale` | 2.4.0.Final | Debezium change data capture (CDC) connector for PlanetScale |
| `debezium-connector-vitess` | 2.4.1.Final | Debezium change data capture (CDC) connector for Vitess |
| `debezium-server` | 3.1.1.Final | Standalone Debezium runtime for streaming change events without Kafka Connect |
| `elasticsearch8` | 8.17.3 | The latest version of Elasticsearch, with support for both x86_64 and aarch64 architectures on Linux and macOS |
| `rustfs` | 1.0.0-alpha.96 | High-performance S3-compatible object storage, built from source |
| `svix-server` | 1.76.1 | The enterprise-ready webhooks service, built from source |
| `terragrunt` | 1.0.0-rc2 | Thin wrapper for Terraform/OpenTofu that provides extra tools for managing infrastructure as code |
| `vitess` | 23.0.3 | Database clustering system for horizontal scaling of MySQL |

## Requirements

- [Nix](https://nixos.org/download.html) with flakes enabled

## Usage

### Add as a Flake Input

Add this repository to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-support.url = "github:fellowapp/nix-support";
  };

  outputs = { self, nixpkgs, nix-support }: {
    # Your outputs here
  };
}
```

### Use the Packages

You can use the packages from this flake in your configuration:

```nix
# In your outputs
outputs = { self, nixpkgs, nix-support }: {
  devShells.x86_64-linux.default =
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    pkgs.mkShell {
      buildInputs = [
        nix-support.packages.x86_64-linux.elasticsearch8
        nix-support.packages.x86_64-linux.debezium
        nix-support.packages.x86_64-linux.atlas
      ];
    };
};
```

### Direct Usage with `nix run`

You can also run the packages directly:

```bash
nix run github:fellowapp/nix-support#elasticsearch8
nix run github:fellowapp/nix-support#atlas
```
