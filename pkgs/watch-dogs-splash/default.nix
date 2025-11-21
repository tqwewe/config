{
  stdenv,
  lib,
  unzip,
}:

stdenv.mkDerivation rec {
  pname = "watch-dogs-splash";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ unzip ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plasma/look-and-feel/watch-dogs-splash

    # Extract the plasmoid
    cd $out/share/plasma/look-and-feel/watch-dogs-splash
    unzip ${src}/watch-dogs-splash.plasmoid

    runHook postInstall
  '';

  meta = with lib; {
    description = "Watch Dogs themed splash screen for KDE Plasma";
    platforms = platforms.linux;
  };
}
