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
    rev = "17f6b19d379da0632d8c165fdb9ade1f9034d381";
    sha256 = "sha256-9+0qgdUn5l9oQQavbnR6rHe5zp5WHhGuRyOXt2Dv8Tw=";
  };

  cargoHash = "sha256-oS6xi8BH5vCVOimYWsDoW0Na7eUXzeHKKSOwpK9wbu8=";

  meta = with lib; {
    description = "Language Server Protocol implementation for Cargo.toml manifests.";
    homepage = "https://github.com/MathiasPius/crates-lsp";
    license = licenses.mit;
    maintainers = [ ];
  };
}
