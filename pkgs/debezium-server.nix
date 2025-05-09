{pkgs}: let
  version = "3.1.1.Final";
in
  pkgs.stdenv.mkDerivation rec {
    # Use 'rec' for easier self-references if needed later
    pname = "debezium-server";
    inherit version;

    src = fetchTarball {
      url = "https://repo1.maven.org/maven2/io/debezium/debezium-server-dist/${version}/debezium-server-dist-${version}.tar.gz";
      # Replace this with the actual SHA256 after the first build attempt
      sha256 = "1cl55qr9p2zhgiay1rlx93hphny6fqjrlcx5r07zv52i29xy8k20";
    };

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [
      pkgs.jre
    ]; # Ensure jre is in buildInputs for JAVA_BINARY path

    startupScriptContent = ''
      # Adapted run script for Nix derivation
      # Use JRE from Nix derivation
      JAVA_BINARY="${pkgs.jre}/bin/java"
      # Base path within the Nix store (substituted during installPhase)
      DEBEZIUM_HOME="__DEBEZIUM_HOME_PLACEHOLDER__"

      # Copyright Debezium Authors.
      # Licensed under the Apache Software License version 2.0

      LIB_PATH="''$DEBEZIUM_HOME/lib/*"
      LIB_CONFIG_PATH="''$DEBEZIUM_HOME/config/lib"
      PATH_SEP=":"

      if [ -n "''${EXTRA_CONNECTOR:-}" ]; then
        EXTRA_CONNECTOR=''${EXTRA_CONNECTOR,,}
        export EXTRA_CONNECTOR_DIR="''$DEBEZIUM_HOME/connectors/debezium-connector-''${EXTRA_CONNECTOR}"
        echo "Connector - ''${EXTRA_CONNECTOR} loaded from ''${EXTRA_CONNECTOR_DIR}"

        if [ -f "''${EXTRA_CONNECTOR_DIR}/jdk_java_options.sh" ]; then
          source "''${EXTRA_CONNECTOR_DIR}/jdk_java_options.sh"
        fi

        EXTRA_CLASS_PATH=""
        if [ -f "''${EXTRA_CONNECTOR_DIR}/extra_class_path.sh" ]; then
          source "''${EXTRA_CONNECTOR_DIR}/extra_class_path.sh"
          LIB_PATH=''${EXTRA_CLASS_PATH}''$LIB_PATH # Note the concatenation
        fi
      fi

      # Correctly find the runner jar
      RUNNER=$(ls "''$DEBEZIUM_HOME"/debezium-server-*runner.jar)

      ENABLE_DEBEZIUM_SCRIPTING=''${ENABLE_DEBEZIUM_SCRIPTING:-false}
      if [[ "''${ENABLE_DEBEZIUM_SCRIPTING}" == "true" ]]; then
        # Append optional libs path
        LIB_PATH="''$LIB_PATH''$PATH_SEP''$DEBEZIUM_HOME/lib_opt/*"
      fi

      # Check if JMX/Metrics scripts exist before sourcing
      if [ -f "''$DEBEZIUM_HOME/jmx/enable_jmx.sh" ]; then
        source "''$DEBEZIUM_HOME/jmx/enable_jmx.sh"
      fi
      if [ -f "''$DEBEZIUM_HOME/lib_metrics/enable_exporter.sh" ]; then
        source "''$DEBEZIUM_HOME/lib_metrics/enable_exporter.sh"
      fi

      # Use DEBEZIUM_OPTS and JAVA_OPTS from environment if set
      # Ensure classpath components are correctly separated
      exec "''$JAVA_BINARY" ''${DEBEZIUM_OPTS:-} ''${JAVA_OPTS:-} -cp \
          "''$RUNNER''$PATH_SEP''$LIB_CONFIG_PATH''$PATH_SEP''$LIB_PATH" \
          io.debezium.server.Main "$@"
    '';

    startupScript = pkgs.writeShellScriptBin "debezium-server" startupScriptContent;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/debezium-server $out/bin

      cp -R . $out/share/debezium-server/
      cp ${startupScript}/bin/debezium-server $out/bin/

      # Substitute the placeholder with the actual out path
      substituteInPlace $out/bin/debezium-server \
        --replace "__DEBEZIUM_HOME_PLACEHOLDER__" "$out/share/debezium-server"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Debezium Server distribution";
      homepage = "https://debezium.io/";
      license = licenses.asl20;
      maintainers = with maintainers; []; # Add your handle here if desired
      platforms = platforms.unix;
    };
  }
