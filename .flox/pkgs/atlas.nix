{pkgs}: let
  # Flox's default catalog may use a different nixpkgs revision. Keep plain
  # `flox build atlas` on the same pin as the flake, as well as CI builds.
  pinnedPkgs = import ../../nix/pinned-nixpkgs.nix {
    system = pkgs.stdenv.hostPlatform.system;
  };
  release = import ../../nix/release.nix {package = "atlas";};
in
  (import ../../pkgs/atlas.nix {pkgs = pinnedPkgs;}).overrideAttrs {
    version = release.version;
    __intentionallyOverridingVersion = true;
  }
