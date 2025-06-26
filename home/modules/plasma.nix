{ pkgs, ... }:
let
  beautifulTreeSplash = pkgs.callPackage ../../pkgs/beautiful-tree-animation-splash.nix { };
in
{
  home.packages = [ beautifulTreeSplash ];

  services.kdeconnect.enable = true;

  programs.plasma = {
    enable = true;

    configFile = {
      kwinrc.Xwayland.Scale = 1;
    };

    input = {
      mice = [
        {
          acceleration = 0.0;
          accelerationProfile = "none";
          enable = true;
          name = "Logitech G703 LS";
          productId = "4086";
          vendorId = "046d";
        }
      ];
    };

    powerdevil = {
      AC = {
        powerProfile = "performance";
      };
    };

    workspace = {
      theme = "breeze-dark"; # Plasma theme
      colorScheme = "BreezeDark"; # Color scheme
      iconTheme = "breeze-dark"; # Icon theme
      cursor.theme = "breeze_cursors"; # Cursor theme

      wallpaper = "/home/ari/dev/tqwewe/config/backgrounds/astro.jpg";

      splashScreen = {
        theme = "BeautifulTreeAnimation";
      };
    };
  };
}
