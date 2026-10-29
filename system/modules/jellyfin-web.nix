{ ... }:
{
  nixpkgs.overlays = [
    (final: prev:
      let
        src = final.fetchFromGitHub {
          owner = "tqwewe";
          repo = "jellyfin-web";
          rev = "ee0746625dbf867da0a1c51a1d60c4039fe35721";
          hash = "sha256-vB53Oaj/ng0PneKXSV9ebJ8PlkmfOENCENCjHwlSjJU=";
        };
      in
      {
        # nixpkgs now builds jellyfin-web with nodejs_24 (npm 11). Our fork (10.11.10)
        # pins npm <11.0.0 with `engine-strict=true`, and its canvas 2.11.2 native dep
        # fails to compile against node 24's ABI. Build with node 22 (npm 10) instead,
        # which satisfies the engine pin and compiles canvas.
        jellyfin-web = (prev.jellyfin-web.override { nodejs_24 = final.nodejs_22; }).overrideAttrs (_old: {
          inherit src;
          # nixpkgs bumped jellyfin-web to 10.11.11, but our fork tracks 10.11.10, so
          # its package-lock.json differs from nixpkgs'. Rebuild npmDeps from our own
          # lockfile so the npmConfigHook integrity check passes.
          npmDeps = final.fetchNpmDeps {
            inherit src;
            name = "jellyfin-web-npm-deps";
            hash = "sha256-DCFgivbZrDufRaB+4PeFxO6ISbEM9lXhXmlzc/5GbVU=";
          };
          postPatch = ''
            substituteInPlace webpack.common.js \
              --replace-fail "git describe --always --dirty" "echo ee0746625dbf867da0a1c51a1d60c4039fe35721"
          '';
        });
      })
  ];
}
