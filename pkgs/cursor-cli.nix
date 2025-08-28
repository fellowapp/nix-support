{pkgs}:
pkgs.stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "latest";
  dontUnpack = true;
  buildInputs = [
    pkgs.cacert
    pkgs.bash
    pkgs.curl
    ];
  src = pkgs.fetchurl {
    url = "https://cursor.com/install";
    sha256 = "sha256-MGfKxi3R+PpSQk8rB4CBL7Iw63G+U+5sk0g2+5OcsnM="; # You'll need to get the actual hash
  };
  installPhase = ''

    # Must fake the home directory to avoid permission issues
    export HOME=$TMPDIR

    # Install cursor-agent
    bash $src

    # Find the symlink target and move it to the output directory

    mkdir -p $out/bin/cursor-agent-dir
    SYMLINK_TARGET=$(readlink $HOME/.local/bin/cursor-agent)
    cp -R $(dirname $SYMLINK_TARGET) $out/bin/cursor-agent-dir
    ln -s $(find $out/bin/cursor-agent-dir -type f -name cursor-agent) $out/bin/cursor-agent
    # chmod +x $out/bin/cursor-agent
  '';
}
