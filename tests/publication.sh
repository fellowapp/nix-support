#!/usr/bin/env bash
# Exercise release reconciliation without Nix, GitHub writes, or Flox credentials.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/state" "$work/build"
export MOCK_STATE="$work/state" PACKAGE=atlas
export GITHUB_SHA=1111111111111111111111111111111111111111
export GITHUB_REPOSITORY=example/packages
unset GITHUB_OUTPUT
export PATH="$work/bin:$PATH"
echo "$GITHUB_SHA" > "$MOCK_STATE/head"

cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ ${FAIL_API:-false} == false ]] || exit 42
case "$1 $2" in
  'api --method')
    if [[ $4 == *'/assets?name='* ]]; then
      name=${4##*name=}
      [[ ! -e $MOCK_STATE/$name ]] || exit 1
      cp "$6" "$MOCK_STATE/$name"
      jq --arg name "$name" '.assets += [{id: $name, name: $name}]' "$MOCK_STATE/release.json" > "$MOCK_STATE/new.json"
      mv "$MOCK_STATE/new.json" "$MOCK_STATE/release.json"
      echo '{}'
    else
      jq '. + {id: 1, assets: []}' "$6" > "$MOCK_STATE/release.json"
      cat "$MOCK_STATE/release.json"
    fi
    ;;
  'api --paginate')
    if [[ -e $MOCK_STATE/release.json ]]; then
      jq '[[.]]' "$MOCK_STATE/release.json"
    else
      echo '[[]]'
    fi
    ;;
  'release create')
    tag=$3
    shift 3
    while [[ $1 != --target ]]; do shift; done
    jq -n --arg tag "$tag" --arg source "$2" \
      '{id: 1, tag_name: $tag, draft: true, target_commitish: $source, assets: []}' > "$MOCK_STATE/release.json"
    ;;
  'release upload')
    name=$(basename "$4")
    [[ ! -e $MOCK_STATE/$name ]] || exit 1
    cp "$4" "$MOCK_STATE/$name"
    jq --arg name "$name" '.assets += [{id: $name, name: $name}]' "$MOCK_STATE/release.json" > "$MOCK_STATE/new.json"
    mv "$MOCK_STATE/new.json" "$MOCK_STATE/release.json"
    ;;
  *)
    case "$2" in
      */git/ref/heads/main) cat "$MOCK_STATE/head" ;;
      */releases/assets/*) cat "$MOCK_STATE/${2##*/}" ;;
      *) echo "Unexpected gh command: $*" >&2; exit 1 ;;
    esac
    ;;
esac
MOCK
chmod +x "$work/bin/gh"

meta=$(jq -n '{
  package: "atlas", pname: "atlas", version: "1.2.0+fellow.test", fingerprint: "test",
  tag: "atlas/v1.2.0+fellow.test", platforms: (["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"] | map({system: .}))
}')
echo "$meta" > "$work/build/metadata.json"
for system in $(jq -r '.platforms[].system' <<< "$meta"); do
  jq -n --argjson metadata "$meta" --arg system "$system" --arg source "$GITHUB_SHA" \
    '{metadata: $metadata, system: $system, source: $source, out: ("/nix/store/" + $system + "-atlas-" + $metadata.version)}' \
    > "$work/build/$system.json"
done

prepare() { bash "$root/scripts/publish-package.sh" prepare "$work/build"; }
expect_failure() {
  if prepare > "$work/failure.log" 2>&1; then
    echo 'Expected reconciliation to fail' >&2
    exit 1
  fi
}
receipt() {
  local system=$1
  jq '{source, system, out, version: .metadata.version, fingerprint: .metadata.fingerprint}' \
    "$work/build/$system.json" > "$work/$system.json"
  gh release upload ignored "$work/$system.json"
}

# First publish creates a draft and includes all four systems.
prepare
jq -e '.pending and (.matrix | length == 4)' "$work/build/plan.json" > /dev/null
[[ -e $MOCK_STATE/publication.json ]]

# A failed platform is retried; successful outputs are left alone. Resume from
# the original commit even when the next push only changes unrelated files.
receipt x86_64-linux
export GITHUB_SHA=2222222222222222222222222222222222222222
echo "$GITHUB_SHA" > "$MOCK_STATE/head"
for file in "$work/build/"*-*.json; do
  jq --arg source "$GITHUB_SHA" '.source = $source' "$file" > "$work/new.json"
  mv "$work/new.json" "$file"
done
prepare
jq -e '.pending and (.matrix | length == 3) and .source == "1111111111111111111111111111111111111111"' \
  "$work/build/plan.json" > /dev/null
for system in aarch64-linux x86_64-darwin aarch64-darwin; do
  # Receipts always identify the original publication commit.
  jq '.source = "1111111111111111111111111111111111111111"' "$work/build/$system.json" > "$work/original.json"
  jq '{source, system, out, version: .metadata.version, fingerprint: .metadata.fingerprint}' \
    "$work/original.json" > "$work/$system.json"
  gh release upload ignored "$work/$system.json"
done

# All uploads succeeded but final verification failed: finalize without uploads.
prepare
jq -e '.pending and (.matrix | length == 0)' "$work/build/plan.json" > /dev/null
jq '.draft = false' "$MOCK_STATE/release.json" > "$work/new.json"
mv "$work/new.json" "$MOCK_STATE/release.json"
prepare
jq -e '(.pending | not) and (.matrix | length == 0)' "$work/build/plan.json" > /dev/null

# An output mismatch must never be silently skipped or overwrite a release.
SYSTEM=x86_64-linux bash "$root/scripts/publish-package.sh" verify-built "$work/build"
cp "$work/build/x86_64-linux.json" "$work/good.json"
jq '.out = "/nix/store/changed-atlas-1.2.0+fellow.test"' "$work/good.json" > "$work/build/x86_64-linux.json"
if SYSTEM=x86_64-linux bash "$root/scripts/publish-package.sh" verify-built "$work/build" > "$work/failure.log" 2>&1; then
  echo 'Expected output mismatch to fail' >&2
  exit 1
fi
cp "$work/good.json" "$work/build/x86_64-linux.json"

# A published release with missing receipts is corruption, not success.
cp "$MOCK_STATE/release.json" "$work/good-release.json"
jq '.assets |= map(select(.name != "x86_64-linux.json"))' "$work/good-release.json" > "$MOCK_STATE/release.json"
expect_failure
cp "$work/good-release.json" "$MOCK_STATE/release.json"

# API failures are not interpreted as "not published".
export FAIL_API=true
expect_failure
unset FAIL_API

# A superseded workflow must not start a publication.
echo 3333333333333333333333333333333333333333 > "$MOCK_STATE/head"
prepare
jq -e '(.pending | not) and (.matrix | length == 0)' "$work/build/plan.json" > /dev/null
echo 'Publication reconciliation checks passed.'
