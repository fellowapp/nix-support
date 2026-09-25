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
| `dolt` | 2.3.5 | MySQL-compatible database with Git-style version control; official binaries for macOS and Linux |
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

### Flox catalog and CI publishing

Atlas is the first package published automatically to the `fellowapp` Flox
catalog. The shared [Packages workflow](.github/workflows/packages.yml) reads
[the package registry](.github/packages.json); additional packages will use the
same workflow as they are migrated.

Every pull request and push to `main` builds and checks each registered package
on `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`. Pull
requests never publish. On `main`, CI compares the resulting store paths with
receipts attached to the corresponding GitHub release and publishes only missing
platform outputs. The `flox` GitHub environment supplies `FLOX_FLOXHUB_TOKEN` to
publishing and catalog-verification jobs.

Both the flake and Flox recipe use **the nixpkgs commit in `flake.lock`**. The
Flox wrapper imports that pin explicitly, including for local builds. CI also
passes the same revision to Flox's `--nixpkgs-url` option so the published build
provenance agrees. This option is supported but hidden in Flox 1.17.0; the CLI
version is pinned in the registry and should be upgraded with the build checks.
The flake tracks Flox's `unstable` mirror because publishing requires a revision
listed in the Flox catalog. The initial migration retains the existing nixpkgs
commit and content hash; only the mirror URL changes. Update it with
`nix flake update nixpkgs`; there is no second nixpkgs pin to synchronize. CI
checks catalog membership before starting the native builds.

Flox package versions use `1.2.0+fellow.<16-character-input-hash>` and tags use
`atlas/v1.2.0+fellow.<same-hash>`. The hash covers the recipe, source hashes,
nixpkgs lock, Flox wrapper/environment, and publishing configuration listed in
the registry. Unrelated commits retain the same identity. Packaging changes
can produce a new publication without changing Atlas's upstream version. The
flake package retains the upstream version.

The `+fellow` suffix is SemVer build metadata, rather than a prerelease suffix.
It identifies a build but does **not** define chronological version ordering.
Before completing a GitHub release, CI checks that both exact-version and
unpinned installations resolve to the expected store paths on all four systems.
If the catalog selects a different build, CI fails and leaves the release draft
for investigation rather than claiming it is the default version.

Each release has a `publication.json` manifest and one verified receipt per
platform. Partial uploads leave a draft; later pushes or a manual run of the
Packages workflow on `main` resume missing work from the original source commit.
If uploads succeeded but final verification failed, a retry only repeats that
verification. GitHub API failures and receipt mismatches fail the job. Releases
are completed only after all four platforms pass; catalog uploads themselves
are not atomic. Build artifacts are temporary, while release receipts are the
durable publication record. Do not delete or edit those receipts.

After publishing, members of the Flox organization can install Atlas with:

```bash
flox install fellowapp/atlas
```

The release notes include the exact version command for reproducible installs.
Existing Flox environments retain their lock until upgraded.

For a local build, ensure the recipe and its shared inputs are tracked by Git:

```bash
flox build atlas
./result-atlas/bin/atlas version
```

`result` and `result-*` (including build logs) are ignored by Git. For the same
build and smoke checks used by CI:

```bash
export PACKAGE=atlas
export SYSTEM=$(nix eval --raw --impure --expr builtins.currentSystem)
bash scripts/publish-package.sh build /tmp/atlas-build
```

Release-recovery checks can be run without credentials or network access:

```bash
bash tests/publication.sh
```
