{pkgs}:
let
  version = "1.0.0-alpha.82";
in
  pkgs.rustPlatform.buildRustPackage rec {
    pname = "rustfs";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "rustfs";
      repo = "rustfs";
      rev = version;
      hash = "sha256-wkqGGzCnAJk8HGIQ4iB0P0SQptrRtWATz2DdE5CpBMo=";
    };

    cargoHash = "sha256-wvc7qpIbh5asE89gvMr+Ga/3dbqfthxCrZHPvO0/mU0=";

    cargoBuildFlags = ["-p" "rustfs"];

    env = {
      RUSTFLAGS = "--cfg tokio_unstable";
      PROTOC = "${pkgs.protobuf}/bin/protoc";
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
      protobuf
    ];

    buildInputs = with pkgs; [
      openssl
    ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      libiconv
    ];

    # Skip tests during build (they require infrastructure setup)
    doCheck = false;

    meta = with pkgs.lib; {
      description = "High-performance S3-compatible object storage";
      homepage = "https://github.com/rustfs/rustfs";
      license = licenses.asl20;
      maintainers = [];
      platforms = platforms.unix;
    };
  }
