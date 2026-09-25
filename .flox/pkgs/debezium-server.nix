{pkgs}: let
  pinnedPkgs = import ../../nix/pinned-nixpkgs.nix {
    system = pkgs.stdenv.hostPlatform.system;
  };
  release = import ../../nix/release.nix {package = "debezium-server";};
in
  (import ../../pkgs/debezium-server.nix {pkgs = pinnedPkgs;}).overrideAttrs {
    version = release.version;
    __intentionallyOverridingVersion = true;
  }
