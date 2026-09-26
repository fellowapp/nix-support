{system}: let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  source = builtins.fetchTree lock.nodes.nixpkgs.locked;
in
  import source {
    inherit system;
    config.allowUnfreePredicate = pkg: (pkg.pname or "") == "elasticsearch";
  }
