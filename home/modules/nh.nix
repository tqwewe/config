{ config, inputs, pkgs, ... }: {
  programs.nh = {
    enable = true;
    package = pkgs.nh;
  };
  home.sessionVariables = {
    NH_FLAKE = "${config.home.homeDirectory}/dev/tqwewe/config";
  };
}
