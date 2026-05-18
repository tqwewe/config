{ inputs, pkgs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager

    ./modules/base.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/kitty.nix
    ./modules/starship.nix
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

  programs.plasma = {
    enable = true;
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      cursor.theme = "breeze_cursors";
    };
    configFile."kwalletrc"."Wallet".Enabled = false;
    configFile."kscreenlockerrc"."Daemon".Autolock = false;
    configFile."kscreenlockerrc"."Daemon".LockOnResume = false;
  };
}
