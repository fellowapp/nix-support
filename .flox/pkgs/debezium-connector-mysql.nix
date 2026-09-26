{pkgs}: let
  pinnedPkgs = import ../../nix/pinned-nixpkgs.nix {
    system = pkgs.stdenv.hostPlatform.system;
  };
in
  import ../../pkgs/debezium-connector-mysql.nix {pkgs = pinnedPkgs;}
