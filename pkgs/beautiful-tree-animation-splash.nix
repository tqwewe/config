{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "beautiful-tree-animation-splash";
  version = "1.0";

  src = ./BeautifulTreeAnimation.tar.gz;

  # No build phase needed for splash screens
  dontBuild = true;
  dontConfigure = true;

  # Install the splash screen files
  installPhase = ''
    runHook preInstall

    # Create the target directory structure
    mkdir -p $out/share/plasma/look-and-feel

    # Copy all files to the output
    cp -r . $out/share/plasma/look-and-feel/BeautifulTreeAnimation

    # Ensure metadata.desktop has correct permissions
    chmod 644 $out/share/plasma/look-and-feel/BeautifulTreeAnimation/metadata.desktop

    runHook postInstall
  '';

  meta = with lib; {
    description = "BeautifulTreeAnimation - Animated Plasma splash screen";
    homepage = "https://store.kde.org/p/1433200";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
