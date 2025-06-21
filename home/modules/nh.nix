{ config, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    package = pkgs.nh;
    clean = {
      enable = true;
      extraArgs = "--keep 2 --keep-since 3d";
    };
  };
  home.sessionVariables = {
    NH_FLAKE = "${config.home.homeDirectory}/dev/tqwewe/config";
  };
}
