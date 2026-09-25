# Builds vitess 23.0.3 with the config/ directory included.
#
# Upstream nixpkgs only installs binaries. Although mysqlctl embeds defaults,
# vttestserver explicitly passes $VTROOT/config/init_db.sql and
# $VTROOT/config/mycnf/test-suite.cnf to it. Keep these files for vttestserver.
# Verified for Vitess 23.0.3 and 24.0.3; see docs/packaging-status.md.
{pkgs}:
pkgs.buildGoModule (finalAttrs: {
  pname = "vitess";
  version = "23.0.3";

  src = pkgs.fetchFromGitHub {
    owner = "vitessio";
    repo = "vitess";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cLpVpdYpMzJX5Y4RBuUp2SbedBHiqG+SRu8Oh+dowFY=";
  };

  vendorHash = "sha256-YhWa5eUeMCqmA+8Mi3lxQTSQ29xMpWWAb2BQPN1/+N8=";

  buildInputs = [pkgs.sqlite];

  subPackages = ["go/cmd/..."];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/config/mycnf
    cp $src/config/init_db.sql $out/config/
    cp $src/config/mycnf/*.cnf $out/config/mycnf/
  '';

  meta = {
    homepage = "https://vitess.io/";
    changelog = "https://github.com/vitessio/vitess/releases/tag/v${finalAttrs.version}";
    description = "Database clustering system for horizontal scaling of MySQL";
    license = pkgs.lib.licenses.asl20;
  };
})
