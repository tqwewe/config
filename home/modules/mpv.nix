{ pkgs, ... }:
let
  uosc = pkgs.mpvScripts.uosc;
  thumbfast = pkgs.mpvScripts.thumbfast;
  mpvConf = ''
    osc=no
    osd-bar=no
  '';
in
{
  programs.mpv = {
    enable = true;
    config = {
      osc = "no";
      osd-bar = "no";
    };
  };

  # Scripts for standalone mpv
  home.file.".config/mpv/scripts/uosc".source = "${uosc}/share/mpv/scripts/uosc";
  home.file.".config/mpv/scripts/thumbfast.lua".source = "${thumbfast}/share/mpv/scripts/thumbfast.lua";
  home.file.".config/mpv/fonts/uosc_icons.otf".source = "${uosc}/share/fonts/uosc_icons.otf";
  home.file.".config/mpv/fonts/uosc_textures.ttf".source = "${uosc}/share/fonts/uosc_textures.ttf";

  # Scripts for jellyfin-mpv-shim (uses its own config_dir)
  home.file.".config/jellyfin-mpv-shim/mpv.conf" = { text = mpvConf; force = true; };
  home.file.".config/jellyfin-mpv-shim/scripts/uosc".source = "${uosc}/share/mpv/scripts/uosc";
  home.file.".config/jellyfin-mpv-shim/scripts/thumbfast.lua".source = "${thumbfast}/share/mpv/scripts/thumbfast.lua";
  home.file.".config/jellyfin-mpv-shim/fonts/uosc_icons.otf".source = "${uosc}/share/fonts/uosc_icons.otf";
  home.file.".config/jellyfin-mpv-shim/fonts/uosc_textures.ttf".source = "${uosc}/share/fonts/uosc_textures.ttf";
}
