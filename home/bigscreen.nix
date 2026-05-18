{ pkgs, ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/kitty.nix
    ./modules/starship.nix
    ./modules/zellij.nix
  ];

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  programs = {
    bat.enable = true;
    btop.enable = true;
    eza.enable = true;
    zoxide.enable = true;
  };

  home.packages = with pkgs; [
    firefox
    ripgrep
  ];
}
