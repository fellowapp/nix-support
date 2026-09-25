# Remaining Flox packaging

Audit: 2026-09-25, against the shared `flake.lock` pin. All ten remaining
package recipes evaluate to derivations on all four configured systems. This
is an evaluation check, not evidence that their native builds or services work.
Atlas and Debezium Server have already completed four-platform publication.

Every additional package needs a version metadata file, a Flox wrapper, a
registry entry, and a meaningful native smoke check. The shared workflow already
supports package-specific smoke scripts, including checks for packages without
an executable. The `debezium` flake attribute is an alias for the MySQL connector,
not a separate package to publish.

| Package | Blocker or limitation | Required work |
| --- | --- | --- |
| `rustfs` | No longer needed locally following the upstream fix. If retained, `1.0.0-alpha.96` is a prerelease. The existing source-built binary reports `rustfs 0.0.5`, not the Git release tag, because the archive lacks Git metadata. | Keep out of the publishing rollout unless needed again. Otherwise handle prerelease resolution and make the CLI report/test the actual upstream release version. |
| `terragrunt` | No longer needed locally: upstream packaging now meets the consumer need. | Exclude from the publishing rollout. Retain the recipe for existing consumers while migrating them upstream. |
| `cursor-cli` | No longer needed locally: consumers will migrate to upstream. The retained recipe uses `latest` and downloads unpinned application files during installation. | Keep the recipe in the repo during consumer migration; do not invest in publishing it to Flox. |
| `vitess` | Still needs the local `config/` installation for `vttestserver`; see the verification below. Also, its source URL uses `finalAttrs.version`, so a version-only Flox override requests a nonexistent packaging-suffixed upstream tag. | Retain the local package. Separate upstream source version from publication version, or preserve `src` explicitly in the wrapper. Check executables and required `config/` files; service-level tests need MySQL infrastructure. |
| `elasticsearch8` | The derivation's `pname` is `elasticsearch`, while the registry/flake name would be `elasticsearch8`. Current output-path validation assumes these names match. License metadata is absent; `passthru.enableUnfree = true` does not declare a license or configure Flox's consumer policy. | Normalize the wrapper name or teach the registry about output names. Add accurate distribution license metadata and applicable consumer settings. Validate all native builds and runtime launchers. Its `util-linux` dependencies do evaluate on macOS at this pin, so they are not a demonstrated platform blocker. |
| `debezium-connector-mysql` | Recipe uses `name` only, with no explicit `pname`/`version`. Ships connector JARs, not a CLI. | Add explicit version/name metadata and a JAR/layout smoke check. Verify that Flox exposes the connector directory at the documented path. |
| `debezium-connector-vitess` | Same missing `pname`/`version` and data-only output issue as the MySQL connector. | Add metadata and a JAR/layout check. |
| `debezium-connector-planetscale` | Has version metadata, but its upstream tag additionally contains `PS20241031.1`. Ships a connector JAR, not a CLI. | Preserve the full upstream tag as a pinned source input and add a JAR/layout check. No additional recipe blocker identified. |
| `dolt` | No longer needed locally: consumers will migrate to the upstream package. | Keep the recipe for existing consumers; exclude it from Flox publishing. |
| `svix-server` | No longer needed locally: consumers will migrate to the upstream package. | Keep the recipe for existing consumers; exclude it from Flox publishing. |

## Vitess upstream verification

Checked both the repository's pinned Nixpkgs revision
[`4bd9165`](https://github.com/NixOS/nixpkgs/blob/4bd9165a9165d7b5e33ae57f3eecbcb28fb231c9/pkgs/by-name/vi/vitess/package.nix)
(Vitess 23.0.3) and upstream master at
[`e140627`](https://github.com/NixOS/nixpkgs/blob/e14062797f790ac8314a80733aa9be014b464b41/pkgs/by-name/vi/vitess/package.nix)
(Vitess 24.0.3). Neither recipe installs `config/`.

The original comment was too broad: standalone `mysqlctl` can use
[embedded initialization SQL and my.cnf defaults](https://github.com/vitessio/vitess/blob/v23.0.3/config/embed.go).
However, the default `vttestserver` environment still constructs file paths for
`$VTROOT/config/init_db.sql` and `$VTROOT/config/mycnf/test-suite.cnf` in both
[23.0.3](https://github.com/vitessio/vitess/blob/v23.0.3/go/vt/vttest/environment.go)
and [24.0.3](https://github.com/vitessio/vitess/blob/v24.0.3/go/vt/vttest/environment.go).
Its [mysqlctl launcher](https://github.com/vitessio/vitess/blob/v24.0.3/go/vt/vttest/mysqlctl.go)
passes these via `--init-db-sql-file` and `EXTRA_MY_CNF`, bypassing the embedded
defaults. Thus upstream is not a drop-in replacement for consumers using this
test-server path. Keep the local recipe until upstream installs these files or
Vitess removes the explicit file dependency. This conclusion is based on source
inspection, not a newly run MySQL integration test.

## Shared limitations

- Flox excludes prereleases by default. Alpha/RC packages require an explicit
  policy in generated consumer manifests, for example
  `[options.semver] allow-pre-releases = true`. See the
  [Flox manifest reference](https://flox.dev/docs/man/manifest.toml/).
- Flox also has an explicit `allow.unfree` consumer setting. Record the actual
  license in each derivation; review the
  [Elasticsearch distribution licensing information](https://www.elastic.co/pricing/faq/licensing)
  when adding its metadata.
- Intel macOS constrains future nixpkgs updates: 26.05 is the last release with
  `x86_64-darwin` support; 26.11 drops it. The current pin works, but moving beyond
  that support boundary requires retaining an older Intel Mac package set or
  changing supported platforms. See the
  [Nixpkgs release notes](https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05).
- `+fellow.<hash>` identifies a package build but does not order SemVer build
  metadata. Exact and unpinned catalog resolution must continue to be checked.
- All registered packages currently share the same four systems. If native
  testing proves a package cannot support one of them, the registry, fingerprint
  calculation, build loops, and release checks need coordinated support for a
  per-package system list. Evaluation alone has not demonstrated such a case.
- Source builds and large Java closures can increase job time and disk use.
  One runner per platform now reuses its Nix store across packages and publishing.

Five packages remain in the publishing rollout: the MySQL, Vitess, and
PlanetScale Debezium connectors, Vitess, and Elasticsearch. The connector
packages have the fewest identified prerequisites.

RustFS, Terragrunt, Cursor, Dolt, and Svix Server are excluded because their
consumers can migrate upstream. Their local recipes remain for compatibility;
do not add them to the Flox publishing registry.
