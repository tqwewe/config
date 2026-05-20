{ inputs, pkgs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager

    ./modules/base.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/nh.nix
    ./modules/openclaw-bigscreen.nix
    ./modules/starship.nix

    # Secrets
    inputs.agenix.homeManagerModules.default
    ../system/modules/secrets.nix
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
    jellyfin-media-player
    ripgrep
    spotify
    vlc
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
