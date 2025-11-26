{pkgs}: let
  version = "1.76.1";
in
  pkgs.rustPlatform.buildRustPackage rec {
    pname = "svix-server";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "svix";
      repo = "svix-webhooks";
      rev = "v${version}";
      hash = "sha256-9ClWC/OHdijmQzKig/o6WhJ9mjlE6pLwvrRKzuO0l3g=";
    };

    sourceRoot = "${src.name}/server";

    cargoHash = "sha256-fOUPaU/1+FvL9hSzWQVouAXmCjI6ppOjJqtgM4+cXf8=";

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
    ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      libiconv
    ];

    # Skip tests during build (they require database setup)
    doCheck = false;

    meta = with pkgs.lib; {
      description = "The enterprise-ready webhooks service";
      homepage = "https://github.com/svix/svix-webhooks";
      license = licenses.mit;
      maintainers = [];
      platforms = platforms.unix;
    };
  }

