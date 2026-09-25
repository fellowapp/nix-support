#!/usr/bin/env bash
# Package CI: build every platform, publish only outputs without durable receipts.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=${GITHUB_REPOSITORY:-fellowapp/nix-support}

die() { echo "Error: $*" >&2; exit 1; }
metadata() { nix eval --json --file nix/release.nix --apply "release: release { package = \"$package\"; }"; }
emit() {
  echo "$1=$2"
  if [[ -n ${GITHUB_OUTPUT:-} ]]; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi
}
find_release() {
  gh api --paginate --slurp "repos/$repo/releases?per_page=100" -H 'Cache-Control: no-cache' |
    jq --arg tag "$tag" '[.[][] | select(.tag_name == $tag)] | first // null'
}
asset() {
  local id
  id=$(jq -r --arg name "$1" '.assets[] | select(.name == $name) | .id' <<< "$release")
  if [[ -n $id ]]; then
    gh api "repos/$repo/releases/assets/$id" -H 'Accept: application/octet-stream'
  else
    echo null
  fi
}
upload() {
  local id name
  id=$(jq -er .id <<< "$release")
  name=$(basename "$1")
  gh api --method POST "https://uploads.github.com/repos/$repo/releases/$id/assets?name=$name" \
    --input "$1" -H 'Content-Type: application/json' > /dev/null
}

smoke() {
  local script
  script=$(jq -r '.smoke_script // empty' <<< "$meta")
  if [[ -n $script ]]; then
    bash "$script" "$1" "$upstream"
    return
  fi
  local actual
  local args=() argument
  while IFS= read -r argument; do args+=("$argument"); done < <(jq -r '.smoke_args[]' <<< "$meta")
  actual=$("$1/$(jq -r .smoke_program <<< "$meta")" "${args[@]}")
  echo "$actual"
  [[ $(head -n 1 <<< "$actual") == "$(jq -r .version_prefix <<< "$meta")$upstream" ]] || die "Unexpected executable version"
}

check_flox() {
  local actual expected
  actual=$(flox --version)
  expected=$(jq -r .flox_version <<< "$meta")
  [[ ${actual%%-*} == "$expected" ]] || die "Expected Flox $expected, found $actual"
}

resolve_once() {
  local dir=$1 exact=$2
  mkdir -p "$dir"
  flox init --bare --name package-ci --dir "$dir" || return 1
  {
    echo 'schema-version = "1.17.0"'
    echo '[options]'
    echo "systems = $systems"
    echo "[install.$package]"
    echo "pkg-path = \"fellowapp/$package\""
    if [[ $exact == true ]]; then echo "version = \"$version\""; fi
  } > "$dir/consumer.toml"
  flox edit --dir "$dir" --file "$dir/consumer.toml" || return 1
  # Check the actual locked version, not just whether the constraint resolved.
  jq -e --arg version "$version" --arg package "$package" --argjson systems "$systems" '
    [.packages[] | select(.install_id == $package)] as $p |
    ($p | map(.system) | sort) == ($systems | sort) and
    all($p[]; .version == $version)
  ' "$dir/.flox/env/manifest.lock" > /dev/null || return 1
  jq --arg package "$package" '[.packages[] | select(.install_id == $package) | {key: .system, value: .outputs.out}] | from_entries' \
    "$dir/.flox/env/manifest.lock" > "$work/outputs.json"
}

resolve_catalog() {
  local exact=$1 attempt
  for attempt in 1 2 3 4 5 6; do
    if resolve_once "$work/consumer-$exact-$attempt" "$exact"; then return; fi
    if [[ $attempt != 6 ]]; then sleep 10; fi
  done
  die 'Catalog did not resolve the expected package version on all requested systems'
}

main() {
  package=${PACKAGE:?Set PACKAGE to a registered package}
  local command=${1:?Expected metadata, build, prepare, publish, or finish}
  local directory=${2:-}
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  if [[ $command == prepare ]]; then
    meta=$(jq .metadata "$directory/x86_64-linux.json")
  else
    meta=$(metadata)
  fi
  version=$(jq -r .version <<< "$meta")
  upstream=$(jq -r .upstream_version <<< "$meta")
  tag=$(jq -r .tag <<< "$meta")
  nixpkgs_url=$(jq -r .nixpkgs_url <<< "$meta")

  case "$command" in
    metadata)
      emit matrix "$(jq -c '{include: .platforms}' <<< "$meta")"
      emit flox_version "$(jq -r .flox_version <<< "$meta")"
      ;;

    build)
      check_flox
      system=$(nix eval --raw --impure --expr builtins.currentSystem)
      [[ $system == "${SYSTEM:?}" ]] || die 'Runner has the wrong architecture'
      nix build --no-link ".#checks.$system.$(jq -r .check <<< "$meta")"
      # Flox 1.17 supports this hidden option. Pinning the CLI and checking the
      # output keeps both the builder and published provenance on flake.lock.
      flox build --nixpkgs-url "$nixpkgs_url" "$package"
      out=$(readlink "result-$package")
      [[ $out == /nix/store/*-"$package-$version" ]] || die 'Unexpected Flox output version'
      smoke "$out"
      mkdir -p "$directory"
      jq -n --argjson metadata "$meta" --arg system "$system" --arg out "$out" \
        --arg source "$(git rev-parse HEAD)" \
        '{metadata: $metadata, system: $system, out: $out, source: $source}' > "$directory/$system.json"
      ;;

    prepare)
      # Older queued/rerun workflows cannot publish over the current main.
      local head source receipt stored missing='[]'
      head=$(gh api "repos/$repo/git/ref/heads/main" --jq .object.sha)
      if [[ $head != "${GITHUB_SHA:?}" ]]; then
        echo '{"pending":false,"matrix":[]}' > "$directory/plan.json"
        return
      fi
      # Every native build must agree on inputs and the workflow source commit.
      for system in $(jq -r '.platforms[].system' <<< "$meta"); do
        jq -e --argjson meta "$meta" --arg source "$GITHUB_SHA" --arg system "$system" '
          .metadata == $meta and .source == $source and .system == $system and
          (.out | startswith("/nix/store/") and endswith("-" + $meta.package + "-" + $meta.version))
        ' "$directory/$system.json" > /dev/null || die "Invalid $system build result"
      done
      release=$(find_release)
      if [[ $release == null ]]; then
        jq -n --arg tag "$tag" --arg source "$GITHUB_SHA" --arg name "$package $version" \
          '{tag_name: $tag, target_commitish: $source, name: $name, draft: true}' > "$work/create.json"
        # Use the write response: GitHub's listing can lag behind draft creation.
        release=$(gh api --method POST "repos/$repo/releases" --input "$work/create.json")
      fi
      stored=$(asset publication.json)
      if [[ $stored == null ]]; then
        [[ $(jq -r .draft <<< "$release") == true ]] || die 'Completed release is missing its manifest'
        source=$(jq -r .target_commitish <<< "$release")
        [[ $source =~ ^[0-9a-f]{40}$ ]] || die 'Draft must target a full source commit'
        stored=$(jq --arg source "$source" '. + {source: $source}' <<< "$meta")
        echo "$stored" > "$work/publication.json"
        upload "$work/publication.json"
      fi
      jq -e --argjson meta "$meta" 'del(.source) == $meta and (.source | test("^[0-9a-f]{40}$"))' \
        <<< "$stored" > /dev/null || die 'Release manifest disagrees with the current build inputs'
      source=$(jq -r .source <<< "$stored")
      for system in $(jq -r '.platforms[].system' <<< "$meta"); do
        receipt=$(asset "$system.json")
        if [[ $receipt == null ]]; then
          missing=$(jq --arg system "$system" --argjson meta "$meta" \
            '. + [$meta.platforms[] | select(.system == $system)]' <<< "$missing")
        else
          jq -e --argjson receipt "$receipt" --arg source "$source" '
            .out == $receipt.out and .system == $receipt.system and
            .metadata.version == $receipt.version and .metadata.fingerprint == $receipt.fingerprint and
            $receipt.source == $source
          ' "$directory/$system.json" > /dev/null || die "Published output changed for $system without a new release identity"
        fi
      done
      if [[ $(jq -r .draft <<< "$release") == false ]]; then
        [[ $missing == '[]' ]] || die 'Completed release has missing platform receipts'
        pending=false
      else
        pending=true
      fi
      jq -n --arg package "$package" --arg source "$source" --argjson pending "$pending" --argjson missing "$missing" \
        '{package: $package, source: $source, pending: $pending, matrix: [$missing[] + {package: $package, source: $source}]}' \
        > "$directory/plan.json"
      ;;

    publish)
      check_flox
      system=${SYSTEM:?}
      [[ $(nix eval --raw --impure --expr builtins.currentSystem) == "$system" ]] || die 'Runner has the wrong architecture'
      release=$(find_release)
      publication=$(asset publication.json)
      source=$(jq -r .source <<< "$publication")
      [[ $(git rev-parse HEAD) == "$source" ]] || die 'Publishing must use the original release commit'
      [[ -z $(git status --porcelain --untracked-files=no) ]] || die 'Publishing requires a clean checkout'
      expected=$(nix eval --raw --impure --expr \
        "(let pkgs = import ./nix/pinned-nixpkgs.nix { system = builtins.currentSystem; }; in import ./.flox/pkgs/$package.nix { inherit pkgs; }).outPath")
      receipt=$(asset "$system.json")
      if [[ $receipt != null ]]; then
        jq -e --arg out "$expected" --arg source "$source" --arg system "$system" --argjson meta "$meta" '
          .out == $out and .source == $source and .system == $system and
          .version == $meta.version and .fingerprint == $meta.fingerprint
        ' <<< "$receipt" > /dev/null || die 'Existing receipt does not match this build'
        return
      fi
      # Safe to repeat after a crash between publishing and saving the receipt.
      flox publish --org fellowapp --nixpkgs-url "$nixpkgs_url" "$package"
      systems=$(jq -nc --arg system "$system" '[$system]')
      resolve_catalog true
      out=$(jq -r --arg system "$system" '.[$system]' "$work/outputs.json")
      smoke "$out"
      [[ $out == "$expected" ]] || die 'Installed output differs from the checked derivation'
      jq -n --arg source "$source" --arg system "$system" --arg out "$out" --argjson meta "$meta" \
        '{source: $source, system: $system, out: $out, version: $meta.version, fingerprint: $meta.fingerprint}' \
        > "$work/$system.json"
      upload "$work/$system.json"
      ;;

    finish)
      check_flox
      release=$(find_release)
      publication=$(asset publication.json)
      systems=$(jq -c '[.platforms[].system]' <<< "$meta")
      expected='{}'
      for system in $(jq -r '.[]' <<< "$systems"); do
        receipt=$(asset "$system.json")
        jq -e --argjson meta "$meta" --argjson publication "$publication" --arg system "$system" '
          .version == $meta.version and .fingerprint == $meta.fingerprint and
          .source == $publication.source and .system == $system
        ' <<< "$receipt" > /dev/null || die "Missing or invalid $system receipt"
        expected=$(jq --arg system "$system" --argjson receipt "$receipt" '. + {($system): $receipt.out}' <<< "$expected")
      done
      for exact in true false; do
        resolve_catalog "$exact"
        jq -e --argjson expected "$expected" '. == $expected' "$work/outputs.json" > /dev/null || die 'Catalog output mismatch'
      done
      {
        echo "$package $upstream, packaged as \`$version\`."
        echo
        echo "Source: \`$(jq -r .source <<< "$publication")\`"
        echo
        echo "nixpkgs: \`$(jq -r .nixpkgs_rev <<< "$meta")\`"
        echo
        echo 'Verified exact-version and unpinned installs across all four platforms.'
        echo
        echo '```sh'
        echo "flox install 'fellowapp/$package@$version'"
        echo '```'
        echo
        echo 'See publication.json and platform receipts for build fingerprints and store paths.'
      } > "$work/notes.md"
      gh release edit "$tag" --repo "$repo" --draft=false --latest=false --notes-file "$work/notes.md"
      ;;
    *) die "Unknown command: $command" ;;
  esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
