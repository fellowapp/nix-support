# nix-support

A Nix flake providing easy access to useful packages that might not be available
or up-to-date in the main nixpkgs repository.

## Currently Supported Packages

| Package | Version | Description |
| --- | --- | --- |
| `atlas` | 1.2.0 | Atlas CLI tool for database schema management on Linux (x86_64 and aarch64) and Apple Silicon macOS |
| `cursor-cli` | latest | [Cursor CLI tool](https://cursor.com/cli) (cluster-agent) |
| `debezium-connector-mysql` | 3.0.8.Final | Debezium's change data capture (CDC) connector for MySQL databases (also exposed as `debezium`) |
| `debezium-connector-planetscale` | 2.4.0.Final | Debezium change data capture (CDC) connector for PlanetScale |
| `debezium-connector-vitess` | 2.4.1.Final | Debezium change data capture (CDC) connector for Vitess |
| `debezium-server` | 3.1.1.Final | Standalone Debezium runtime for streaming change events without Kafka Connect |
| `elasticsearch8` | 8.17.3 | Elasticsearch on Linux (x86_64 and aarch64) and Apple Silicon macOS |
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

Atlas and Debezium Server are published automatically to the `fellowapp` Flox
catalog. The [Packages workflow](.github/workflows/packages.yml) builds every
expression in [`.flox/pkgs/`](.flox/pkgs/) on `x86_64-linux`, `aarch64-linux`, and
`aarch64-darwin`. The workflow declares its runners directly; keep its matrix
aligned with the flake's [`nix/systems.nix`](nix/systems.nix). Packages retained
only under `pkgs/` are not published.

Each platform builds all registered packages with `flox build`, checks that
their store paths match the flake packages, and runs each package's
`passthru.smokeTest` against its Flox output. To add a package, expose it in the
flake and add a Flox expression and a smoke test accepting its output path.
There is no separate publishing registry or version metadata file.

Pull requests only build and test. On `main`, each native runner then calls
`flox publish --org fellowapp` for every registered package. GitHub Actions
concurrency allows one main workflow to run at a time without interruption.
A new queued run replaces any previous pending run; newer PR runs also cancel
older running checks. Concurrency does not prevent manual reruns of old commits.
The `flox` GitHub environment supplies `FLOX_FLOXHUB_TOKEN` to publishing and
catalog-verification jobs. Failed publications can be retried by rerunning the
workflow; Flox handles already-published builds.

Both the flake and Flox expressions use **the nixpkgs commit in `flake.lock`**.
The Flox wrappers import that pin explicitly, including for local builds. CI
also passes it to Flox's `--nixpkgs-url` option so publication metadata agrees.
This option is supported but hidden in Flox 1.17.0; the workflow pins the CLI
version. The flake tracks Flox's `unstable` mirror because publishing requires a
revision listed in the Flox catalog; `flox publish` validates compatibility.
Each runner reads the pin directly from the lockfile. Update it with
`nix flake update nixpkgs`.

Packages keep their upstream versions, such as `1.2.0` and `3.1.1.Final`.
Dependency and packaging changes are identified by Nix derivation and output
paths, without adding a version suffix. A version constraint selects an
upstream version; the consumer's Flox lockfile pins the particular build.
Existing environments retain their locked builds until upgraded.

After all native jobs succeed, CI resolves both exact-version and unpinned
installs across all supported systems and compares the catalog's selected
versions and output paths with the tested builds. It retries briefly for
catalog propagation and fails if different builds are selected. This also
checks resolution alongside previously published versions with hash suffixes.
Build records are passed between jobs as temporary Actions artifacts.

Only after verification does CI create GitHub releases, tagged
`atlas/v1.2.0`, for example. These releases contain installation notes and no
uploaded assets. Existing releases are left in place when dependencies are
rebuilt under the same upstream version. Releases do not control publication
or retries, and publication across platforms is not atomic.

Debezium Server's smoke test checks the version embedded in its core JAR, the
runner JAR, and the packaged launcher with its native JRE. It does not start
connectors or require an external database or message broker.

Members of the Flox organization can install the packages with:

```bash
flox install fellowapp/atlas
flox install fellowapp/debezium-server
```

For a local build, ensure the recipes and their shared inputs are tracked by Git:

```bash
flox build
./result-atlas/bin/atlas version
```

`result` and `result-*` (including build logs) are ignored by Git. To run the
same smoke tests as CI against those outputs:

```bash
system=$(nix eval --raw --impure --expr builtins.currentSystem)
for recipe in .flox/pkgs/*.nix; do
  package=${recipe##*/}
  package=${package%.nix}
  check=$(nix build --no-link --print-out-paths ".#packages.$system.$package.passthru.smokeTest")
  "$check" "$(readlink "result-$package")"
done
```
