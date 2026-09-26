{package}: let
  systems = import ./systems.nix;
  pkgs = import ./pinned-nixpkgs.nix {system = builtins.head systems;};
  upstream = import (../pkgs + "/${package}.nix") {inherit pkgs;};
  nixpkgs = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs.locked;
  fingerprint = import ./package-fingerprint.nix {inherit package;};
  version = "${upstream.version}+fellow.${builtins.substring 0 6 fingerprint}";
in {
  inherit fingerprint version package;
  inherit (upstream) pname;
  schema = 2;
  catalog = "fellowapp";
  upstream_version = upstream.version;
  tag = "${package}/v${version}";
  platforms = map (system: {inherit system;}) systems;
  nixpkgs_rev = nixpkgs.rev;
  nixpkgs_url = "https://github.com/${nixpkgs.owner}/${nixpkgs.repo}?rev=${nixpkgs.rev}";
}
