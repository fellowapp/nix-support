#!/usr/bin/env bash
set -euo pipefail
out=${1:?Expected package output}
version=${2:?Expected upstream version}
dist="$out/share/debezium-server"
test -s "$dist/debezium-server-dist-$version-runner.jar"
actual=$(unzip -p "$dist/lib/debezium-core-$version.jar" io/debezium/build.version)
[[ $actual == "version=$version" ]]
# Exercise the actual launcher and its pinned JRE without starting connectors.
JAVA_OPTS=-version DEBEZIUM_OPTS='' EXTRA_CONNECTOR='' ENABLE_DEBEZIUM_SCRIPTING=false \
  "$out/bin/debezium-server"
echo "Debezium Server $version: distribution and Java launcher checks passed."
