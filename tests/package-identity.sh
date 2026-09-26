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
identity() { nix eval --json --file "$work/nix/release.nix" --apply 'release: release { package = "atlas"; }' | jq -r .version; }
before=$(identity)
[[ $before =~ \+fellow\.[0-9a-f]{6}$ ]]
nix eval --json --file "$work/nix/release.nix" --apply 'release: release { package = "atlas"; }' |
  jq -e '.tag == ("atlas/v" + .version) and (.fingerprint | test("^[0-9a-f]{64}$"))' > /dev/null
echo '{pkgs}: pkgs.hello' > "$work/.flox/pkgs/unrelated.nix"
echo 'changed CI implementation' > "$work/.github/workflows/packages.yml"
[[ $(identity) == "$before" ]]
# A change in the actual recipe must change the package identity.
sed 's/version = "1.2.0"/version = "1.2.999"/' "$work/pkgs/atlas.nix" > "$work/new.nix"
mv "$work/new.nix" "$work/pkgs/atlas.nix"
[[ $(identity) != "$before" ]]
echo 'Package identity checks passed.'
