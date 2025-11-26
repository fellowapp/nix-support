# nix-support

A Nix flake providing easy access to useful packages that might not be available
or up-to-date in the main nixpkgs repository.

## Currently Supported Packages

- **Elasticsearch 8.17.3** - The latest version of Elasticsearch, with support
  for both x86_64 and aarch64 architectures on Linux and macOS
- **Debezium MySQL Connector 3.0.8** - Debezium's change data capture (CDC)
  connector for MySQL databases
- **Atlas 0.32.1** - Atlas CLI tool for database schema management, with support
  for both x86_64 and aarch64 architectures on Linux and macOS
- **Cursor-cli** - [Cursor CLI tool](https://cursor.com/cli) (cluster-agent)
- **Svix-server 1.76.1** - The enterprise-ready webhooks service, built from source

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
