{pkgs}: let
  buildGo126Module = pkgs.buildGoModule.override {go = pkgs.go_1_26;};
in
  buildGo126Module rec {
    pname = "terragrunt";
    version = "1.0.0-rc2";

    src = pkgs.fetchFromGitHub {
      owner = "gruntwork-io";
      repo = "terragrunt";
      tag = "v${version}";
      hash = "sha256-h7TGnDXS7UgOYtF+Mx39eJ7V2cv3voLOSR3WNMnaddU=";
    };

    nativeBuildInputs = [
      pkgs.mockgen
    ];

    proxyVendor = true;

    preBuild = ''
      make generate-mocks
    '';

    vendorHash = "sha256-yJdDhS5nA8ZFXOkNv+6/OYxUndn3J8FXxllXAVEKqEQ=";

    subPackages = ["."];

    doCheck = false;

    ldflags = [
      "-s"
      "-X github.com/gruntwork-io/go-commons/version.Version=v${version}"
      "-extldflags '-static'"
    ];

    meta = with pkgs.lib; {
      homepage = "https://terragrunt.gruntwork.io";
      changelog = "https://github.com/gruntwork-io/terragrunt/releases/tag/v${version}";
      description = "Thin wrapper for Terraform that supports locking for Terraform state and enforces best practices";
      mainProgram = "terragrunt";
      license = licenses.mit;
    };
  }
