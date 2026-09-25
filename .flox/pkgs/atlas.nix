{pkgs}:
# Share the package recipe with the flake; Flox supplies its own nixpkgs set.
import ../../pkgs/atlas.nix {inherit pkgs;}
