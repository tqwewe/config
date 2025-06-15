{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "crates-lsp";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "MathiasPius";
    repo = "crates-lsp";
    rev = "main";
    sha256 = "sha256-r+bSc98YsUc5ANc8WbXI8N2wdEF53uJoWQbsBHYmrGc=";
  };

  cargoHash = "sha256-UqQxhcDdD0b9rIG+nrAops2v5vcyj/pkL/3FLW3bsDQ=";

  meta = with lib; {
    description = "Language Server Protocol implementation for Cargo.toml manifests.";
    homepage = "https://github.com/MathiasPius/crates-lsp";
    license = licenses.mit;
    maintainers = [ ];
  };
}
