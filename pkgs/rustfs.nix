{pkgs}: let
  version = "1.0.0-alpha.96";
in
  pkgs.rustPlatform.buildRustPackage rec {
    pname = "rustfs";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "rustfs";
      repo = "rustfs";
      rev = version;
      hash = "sha256-biJ46HmQ5zyuWB6wa51m8YbR0VxslSPI0FOQKUgwwMY=";
    };

    cargoHash = "sha256-sBaNV+lCdMgpXPOWng58+C4kdpez9E9ZDetZGOoyWbk=";

    cargoBuildFlags = ["-p" "rustfs"];

    env = {
      RUSTFLAGS = "--cfg tokio_unstable";
      PROTOC = "${pkgs.protobuf}/bin/protoc";
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
      protobuf
    ];

    buildInputs = with pkgs;
      [
        openssl
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
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
