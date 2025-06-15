{
  programs.plasma = {
    enable = true;

    configFile = {
      kwinrc.Xwayland.Scale = 1;
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
