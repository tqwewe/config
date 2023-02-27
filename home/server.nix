{ pkgs, ... }:

{
  imports = [
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
  ];

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  # User programs & packages
  programs.bat.enable = true;
  programs.exa.enable = true;
  programs.starship.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    ripgrep
  ];
}
