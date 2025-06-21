{
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
      lookAndFeel = "org.kde.breezedark.desktop";
      wallpaper = "/home/ari/dev/tqwewe/config/backgrounds/astro.jpg";
    };
  };
}
