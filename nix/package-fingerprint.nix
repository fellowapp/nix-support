{package}: let
  config = builtins.fromJSON (builtins.readFile ../.github/packages.json);
  derivations = map (platform: let
    pkgs = import ./pinned-nixpkgs.nix {inherit (platform) system;};
  in {
    inherit (platform) system;
    drv = (import (../pkgs + "/${package}.nix") {inherit pkgs;}).drvPath;
  }) (builtins.sort (a: b: a.system < b.system) config.platforms);
in
  builtins.hashString "sha256" (builtins.toJSON {
    inherit derivations;
    wrapper = builtins.hashString "sha256" (builtins.readFile (../.flox/pkgs + "/${package}.nix"));
  })
