{pkgs}: let
  pinnedPkgs = import ../../nix/pinned-nixpkgs.nix {
    system = pkgs.stdenv.hostPlatform.system;
  };
in
  import ../../pkgs/elasticsearch8.nix {pkgs = pinnedPkgs;}
