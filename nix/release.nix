{package}: let
  config = builtins.fromJSON (builtins.readFile ../.github/packages.json);
  definition = config.packages.${package};
  upstream = builtins.fromJSON (builtins.readFile (../. + "/${definition.version_file}"));
  nixpkgs = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs.locked;
  derivationFingerprint = import ./package-fingerprint.nix {inherit package;};
  # Preserve versions already uploaded before switching from file-based hashes.
  # This alias applies only to the exact original set of native derivations.
  initial = definition.initial_publication or null;
  fingerprint =
    if initial != null && initial.derivation_fingerprint == derivationFingerprint
    then initial.fingerprint
    else derivationFingerprint;
  version = "${upstream.version}+fellow.${builtins.substring 0 16 fingerprint}";
in {
  inherit fingerprint version;
  schema = 1;
  inherit package;
  inherit (definition) check;
  smoke_script = definition.smoke_script or null;
  smoke_program = definition.smoke_program or null;
  smoke_args = definition.smoke_args or [];
  version_prefix = definition.version_prefix or "";
  catalog = "fellowapp";
  upstream_version = upstream.version;
  tag = "${package}/v${version}";
  inherit (config) flox_version platforms;
  nixpkgs_rev = nixpkgs.rev;
  nixpkgs_url = "https://github.com/${nixpkgs.owner}/${nixpkgs.repo}?rev=${nixpkgs.rev}";
}
