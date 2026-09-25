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
| `terragrunt` | `1.0.0-rc2` is also a prerelease. The current consumer checks leave prereleases disabled. | Add explicit prerelease handling to the registry/consumer checks and document it for users, or intentionally upgrade to a stable release. Native builds still need validation, including the recipe's static-link flags on macOS. |
| `cursor-cli` | `version = "latest"`; the fetched installer is hashed, but it downloads the actual application during an ordinary build. Those application inputs are neither pinned nor fetched as fixed-output dependencies. | Package versioned, hashed artifacts for each system. Remove network downloads from `installPhase`, then validate the executable layout and runtime dependencies. |
| `vitess` | Its source URL uses `finalAttrs.version`. Applying the existing version-only Flox override changes `v23.0.3.tar.gz` into the nonexistent packaging-suffixed upstream tag. This was reproduced by evaluating the override. | Separate upstream source version from publication version, or preserve `src` explicitly in the wrapper. Check representative executables and the required `config/` files; service-level tests need MySQL infrastructure. |
| `elasticsearch8` | The derivation's `pname` is `elasticsearch`, while the registry/flake name would be `elasticsearch8`. Current output-path validation assumes these names match. License metadata is absent; `passthru.enableUnfree = true` does not declare a license or configure Flox's consumer policy. | Normalize the wrapper name or teach the registry about output names. Add accurate distribution license metadata and applicable consumer settings. Validate all native builds and runtime launchers. Its `util-linux` dependencies do evaluate on macOS at this pin, so they are not a demonstrated platform blocker. |
| `debezium-connector-mysql` | Recipe uses `name` only, with no explicit `pname`/`version`. Ships connector JARs, not a CLI. | Add explicit version/name metadata and a JAR/layout smoke check. Verify that Flox exposes the connector directory at the documented path. |
| `debezium-connector-vitess` | Same missing `pname`/`version` and data-only output issue as the MySQL connector. | Add metadata and a JAR/layout check. |
| `debezium-connector-planetscale` | Has version metadata, but its upstream tag additionally contains `PS20241031.1`. Ships a connector JAR, not a CLI. | Preserve the full upstream tag as a pinned source input and add a JAR/layout check. No additional recipe blocker identified. |
| `dolt` | Already has pinned binaries for all four systems and explicit version metadata. | Add the normal Flox integration and a `dolt version` check. No additional recipe blocker identified; native build/install checks remain to be run. |
| `svix-server` | No concrete evaluation blocker identified. Builds Rust from source; upstream tests are disabled because they require a database. | Add the normal integration and a CLI smoke check; verify native builds and budget for compilation. A CLI check will not establish PostgreSQL/service correctness. |

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

Dolt and the connector packages have the fewest identified prerequisites.
RustFS is intentionally deferred, rather than a candidate for the next rollout.
