{
  description = "A Nix flake providing easy access to useful packages that might not be available or up-to-date in the main nixpkgs repository.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        debezium = pkgs.stdenv.mkDerivation {
          name = "debezium";
          src = (
            fetchTarball {
              url = "https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/3.0.8.Final/debezium-connector-mysql-3.0.8.Final-plugin.tar.gz";
              sha256 = "0mylvls3d8p1hx01kr0vd7mqaplxs98mhf0dp1i6zhhmzlaqf199";
            }
          );
          installPhase = ''
            mkdir -p $out/debezium/debezium-connector-mysql
            cp -R . $out/debezium/debezium-connector-mysql
          '';
        };
        elasticsearch8 =
          let
            arch =
              with pkgs.stdenv.hostPlatform;
              if isx86_64 then
                "x86_64"
              else if isAarch64 then
                "aarch64"
              else
                throw "Unsupported architecture: ${system}";
            plat = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
            hashes = {
              "x86_64-linux" =
                "sha512-au9PyE67/JjmZiQYxzTqicro5TqNbB+9U1KAe8Qn4EDmK+VotQKr3Ot6L1dTTq5g4xcS0Fg9N1L9Obe4o2MtOw==";
              "aarch64-linux" =
                "sha512-au9PyE67/JjmZiQYxzTqicro5TqNbB+9U1KAe8Qn4EDmK+VotQKr3Ot6L1dTTq5g4xcS0Fg9N1L9Obe4o2MtOw==";
              "x86_64-darwin" =
                "sha512-R7YbSehFAGJLwrSx6FNs6CArYUyo1JZc4VKZQJ5fbDVBpyhwFmtI6PWSVlLYyx2qnj9Yd/7YBTuhrj9sqQDYZQ==";
              "aarch64-darwin" =
                "sha512-R7YbSehFAGJLwrSx6FNs6CArYUyo1JZc4VKZQJ5fbDVBpyhwFmtI6PWSVlLYyx2qnj9Yd/7YBTuhrj9sqQDYZQ==";
            };
          in
          pkgs.stdenv.mkDerivation rec {
            pname = "elasticsearch";
            version = "8.17.3";

            src = pkgs.fetchurl {
              url = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${version}-${plat}-${arch}.tar.gz";
              hash = hashes."${arch}-${plat}";
            };

            postPatch = ''
              substituteInPlace bin/elasticsearch-env --replace \
                "ES_CLASSPATH=\"\$ES_HOME/lib/*\"" \
                "ES_CLASSPATH=\"$out/lib/*\""
              substituteInPlace bin/elasticsearch-cli --replace \
                "ES_CLASSPATH=\"\$ES_CLASSPATH:\$ES_HOME/\$additional_classpath_directory/*\"" \
                "ES_CLASSPATH=\"\$ES_CLASSPATH:$out/\$additional_classpath_directory/*\""
            '';

            nativeBuildInputs = [
              pkgs.makeBinaryWrapper
            ] ++ pkgs.lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.autoPatchelfHook;

            buildInputs = [
              pkgs.jre_headless
              pkgs.util-linux
              pkgs.zlib
            ];

            runtimeDependencies = [ pkgs.zlib ];

            installPhase = ''
              mkdir -p $out
              cp -R bin config lib modules plugins $out
              chmod +x $out/bin/*
              substituteInPlace $out/bin/elasticsearch \
                --replace 'bin/elasticsearch-keystore' "$out/bin/elasticsearch-keystore"
              wrapProgram $out/bin/elasticsearch \
                --prefix PATH : "${
                  pkgs.lib.strings.makeBinPath [
                    pkgs.util-linuxMinimal
                    pkgs.coreutils
                    pkgs.gnugrep
                  ]
                }" \
                --set ES_JAVA_HOME "${pkgs.jre_headless}"
              wrapProgram $out/bin/elasticsearch-plugin --set ES_JAVA_HOME "${pkgs.jre_headless}"
            '';

            passthru = {
              enableUnfree = true;
            };
          };
      in
      {
        packages = {
          inherit elasticsearch8 debezium;
        };
      }
    );
}
