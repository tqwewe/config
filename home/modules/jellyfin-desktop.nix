{ pkgs, config, ... }:
let
  appimageFile = pkgs.runCommand "JellyfinDesktop.AppImage" {
    src = pkgs.fetchurl {
      # nightly.link serves the latest artifact of the named workflow/branch. Upstream
      # renamed the workflow build-linux-appimage -> build-appimage and uses the `master`
      # default branch, so the old main/build-linux-appimage path now 404s.
      url = "https://nightly.link/jellyfin/jellyfin-desktop/workflows/build-appimage/master/linux-appimage-x86_64.zip";
      hash = "sha256-MabL967zjaSILmIQk6o1sGc7Q2SXQWe1xXOjOZ0vccs=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
  } ''
    unzip $src
    cp *.AppImage $out
  '';

  extracted = pkgs.appimageTools.extract {
    pname = "jellyfin-desktop";
    version = "3.0.0-dev";
    src = appimageFile;
    # AppRun execs the bundled ld.so with a fixed --library-path that never includes
    # /run/opengl-driver/lib, so libcuda (nvdec) and NVIDIA's EGL wayland/gbm platform
    # libs can't be found and rendering falls back to llvmpipe. Append the driver dir.
    postExtract = ''
      chmod u+w $out/AppRun
      substituteInPlace $out/AppRun \
        --replace-fail ':/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu"' \
                       ':/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/run/opengl-driver/lib"'
    '';
  };

  appimage = pkgs.appimageTools.wrapAppImage {
    pname = "jellyfin-desktop";
    version = "3.0.0-dev";
    src = extracted;
    # The FHS sandbox's /etc is a tmpfs that omits /etc/egl, so libEGL_nvidia can't find
    # its wayland/gbm external platforms and Qt falls back to Mesa llvmpipe (CPU rendering).
    extraBwrapArgs = [ "--ro-bind-try /etc/egl /etc/egl" ];
  };
in
{
  home.packages = [ appimage ];

  home.file.".local/share/icons/hicolor/scalable/apps/jellyfin-desktop.svg".source =
    "${extracted}/usr/share/icons/hicolor/scalable/apps/org.jellyfin.JellyfinDesktop.svg";

  xdg.desktopEntries.jellyfin-desktop = {
    name = "Jellyfin Desktop";
    exec = "jellyfin-desktop --tv %U";
    icon = "${config.home.homeDirectory}/.local/share/icons/hicolor/scalable/apps/jellyfin-desktop.svg";
    comment = "Jellyfin native desktop client";
    categories = [ "AudioVideo" "Video" ];
  };
}
