{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../modules/base.nix
    ../modules/fish.nix
    ../modules/jellyfin.nix
    ../modules/kde.nix
    ../modules/locale.nix
    ../modules/movie-server.nix
    ../modules/nh.nix
    ../modules/nvidia.nix
    ../modules/pipewire.nix
  ];

  networking = {
    hostName = "bigscreen";
    dhcpcd.enable = true;
    enableIPv6 = true;
    networkmanager.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.displayManager.defaultSession = "plasma";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ari";

  users.users.ari = {
    initialPassword = "";
    isNormalUser = true;
    description = "Ari Seyhun";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDH5/fcSpNbszARLuWCdYzAHyC+XkkCZo/I7CQopbBlLG7hstcsem80c/bJnIZ5Rr+bmyYIQeuFnq5rKSIuYJw/yhoGwSqhk8Xg8qUJomKCyodCc9WY50zjQEV/qtD0RYDhCT5hlEIfKRiJBnFyWcYEavDOH6U6PUdMb1HWGPsDC7QtUiosgNd51c+t+JW5dQ+aFDCVHypEunyESMfJhTite2w8gECXRRAudpzh/GFl1hT++AXHN5VxLKfArmSKY/aRVrr8Yc5DRgLqbxfYcHLDf1k6fFn/z9uvhWm55JoAmQ7hT6GvNzu5cUiEGV+JMly4iED0dnlclo+vMMIZUT6WcAN6QomFUK0A9pEf2OM1SaHhATzWCdpm6giSWaxxvlvZh/DoM4gS8mm1msPofAA9FTgLLfwFmE3v9Jsi2CrOQzmkPJZnEYPdeAa/QlRqPvmnVTNJBrbkXZMaRwuWypDrXl0ze9Fgxk4jw8joIYr0WZYHCgKe9X/Kbz83gcPlCac= rain@arch"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsnUFtG1IYtexjTjCbvCknN/lr3OuittQzsWxAlajYP ariseyhun@live.com.au"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZswi6XsdjP5E/O0c9zgmMNCA4cHQtzznhGuHT2eX8S ari@desktop"
    ];
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };

  nix.settings.trusted-users = [
    "root"
    "ari"
  ];

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PermitRootLogin = "no";
      AllowUsers = [ "ari" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 2222 8080 ];

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.kernelModules = [ "hid-apple" ];

  hardware.nvidia.open = false;
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  security.sudo.wheelNeedsPassword = false;

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };
  security.polkit.enable = true;

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
}
