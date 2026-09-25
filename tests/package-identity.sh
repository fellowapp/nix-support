#!/usr/bin/env bash
# Infrastructure changes must not create a new package version.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/.github/workflows" "$work/.flox"
cp -R "$root/.flox/pkgs" "$work/.flox/"
cp -R "$root/nix" "$root/pkgs" "$work/"
cp "$root/flake.lock" "$work/"
cp "$root/.github/packages.json" "$work/.github/"
identity() { nix eval --json --file "$work/nix/release.nix" --apply 'release: release { package = "atlas"; }' | jq -r .version; }
before=$(identity)
[[ $before =~ \+fellow\.[0-9a-f]{6}$ ]]
nix eval --json --file "$work/nix/release.nix" --apply 'release: release { package = "atlas"; }' |
  jq -e '.tag == ("atlas/v" + .version) and (.fingerprint | test("^[0-9a-f]{64}$"))' > /dev/null
jq '.packages.unrelated = {version_file: "unused.json"} | .platforms[0].runner = "another-runner"' \
  "$work/.github/packages.json" > "$work/new.json"
mv "$work/new.json" "$work/.github/packages.json"
echo 'changed CI implementation' > "$work/.github/workflows/packages.yml"
[[ $(identity) == "$before" ]]
# A change in the actual recipe must still invalidate the migration alias.
jq '.version = "1.2.999"' "$work/pkgs/atlas.json" > "$work/new.json"
mv "$work/new.json" "$work/pkgs/atlas.json"
[[ $(identity) != "$before" ]]
echo 'Package identity checks passed.'
