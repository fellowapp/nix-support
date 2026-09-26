#!/usr/bin/env bash
set -euo pipefail
out=${1:?Expected package output}
connector=${2:?Expected connector name}
version=${3:?Expected upstream version}
directory="$out/debezium/debezium-connector-$connector"
suffix=''
case "$connector" in
  mysql) class=MySqlConnector ;;
  vitess) class=VitessConnector ;;
  planetscale) class=PlanetScaleConnector; suffix=-jar-with-dependencies ;;
  *) echo "Unknown connector: $connector" >&2; exit 1 ;;
esac
jar="$directory/debezium-connector-$connector-$version$suffix.jar"
unzip -tqq "$jar"
unzip -p "$jar" "io/debezium/connector/$connector/$class.class" > /dev/null
unzip -p "$jar" "META-INF/maven/io.debezium/debezium-connector-$connector/pom.properties" |
  grep -Fx "version=$version"
if [[ $connector != planetscale ]]; then
  test -s "$directory/debezium-api-$version.jar"
  unzip -tqq "$directory/debezium-core-$version.jar"
fi
echo "Debezium $connector $version: connector class, version, and JAR checks passed."
