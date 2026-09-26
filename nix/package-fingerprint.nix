{package}: let
  systems = import ./systems.nix;
  derivations = map (system: let
    pkgs = import ./pinned-nixpkgs.nix {inherit system;};
  in {
    inherit system;
    drv = (import (../pkgs + "/${package}.nix") {inherit pkgs;}).drvPath;
  }) (builtins.sort builtins.lessThan systems);
in
  builtins.hashString "sha256" (builtins.toJSON {
    inherit derivations;
    wrapper = builtins.hashString "sha256" (builtins.readFile (../.flox/pkgs + "/${package}.nix"));
  })
