{pkgs}: let
  pinnedPkgs = import ../../nix/pinned-nixpkgs.nix {
    system = pkgs.stdenv.hostPlatform.system;
  };
in
  import ../../pkgs/vitess.nix {pkgs = pinnedPkgs;}
