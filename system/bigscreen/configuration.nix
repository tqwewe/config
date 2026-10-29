{ pkgs, lib, config, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../modules/base.nix
    ../modules/fish.nix
    ../modules/jellyfin.nix
    ../modules/jellyfin-web.nix
    ../modules/kde.nix
    ../modules/locale.nix
    ../modules/movie-server.nix
    ../modules/nh.nix
    ../modules/nvidia.nix
    ../modules/pipewire.nix
    ../modules/plasma-bigscreen.nix
    ../modules/steam.nix
  ];

  networking = {
    hostName = "bigscreen";
    dhcpcd.enable = true;
    enableIPv6 = true;
    networkmanager.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.displayManager.defaultSession = "plasma-bigscreen-wayland";
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

  networking.firewall.allowedTCPPorts = [ 53 80 2222 8080 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.tailscale.enable = true;

  services.dnsmasq = {
    enable = true;
    settings = {
      address = "/bigscreen/100.106.216.67";
      # Answer *.bigscreen authoritatively so AAAA (IPv6) queries return an
      # immediate empty reply instead of being forwarded to Tailscale's resolver
      # (100.100.100.100), whose split-DNS route loops `bigscreen` back here and
      # black-holes. Without this, every getaddrinfo() stalls ~10-25s on the AAAA
      # half after the negative cache expires — the "cold start" on remote loads.
      local = "/bigscreen/";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "http://jellyfin.bigscreen".extraConfig     = "reverse_proxy 127.0.0.1:8096";
      "http://seerr.bigscreen".extraConfig        = "reverse_proxy 127.0.0.1:5055";
      "http://radarr.bigscreen".extraConfig       = "reverse_proxy 127.0.0.1:7878";
      "http://sonarr.bigscreen".extraConfig       = "reverse_proxy 127.0.0.1:8989";
      "http://prowlarr.bigscreen".extraConfig     = "reverse_proxy 127.0.0.1:9696";
      "http://bazarr.bigscreen".extraConfig       = "reverse_proxy 127.0.0.1:6767";
      "http://qbittorrent.bigscreen".extraConfig  = "reverse_proxy 127.0.0.1:8080";
      "http://maintainerr.bigscreen".extraConfig  = "reverse_proxy 127.0.0.1:6246";
      "http://xteve.bigscreen".extraConfig        = "reverse_proxy 127.0.0.1:34400";
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  systemd.services.bluetooth-autopower = {
    description = "Power on Bluetooth adapter";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    # bluetoothd often hasn't registered hci0 yet at this point ("No default controller
    # available"), so retry for a bit instead of failing the boot.
    startLimitBurst = 10;
    startLimitIntervalSec = 60;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/bluetoothctl power on";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Power-off sometimes leaves the machine running (fans/lights on) after "System Power Off",
  # while reboot works. On this Intel B250 board a wake event raised while running (USB/xHCI,
  # e1000e LAN, AX200 Wi-Fi port, GPU port) can stay pending and make the chipset ignore the
  # ACPI S5 request. Nothing here is used to wake the machine, so disarm those wake sources.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:14.0|0000:00:1f.6|0000:00:1d.2|0000:00:1c.0", ATTR{power/wakeup}="disabled"
  '';

  boot.kernelModules = [ "hid-apple" ];

  hardware.nvidia.open = lib.mkForce false;
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580;

  boot.kernelParams = [ "drm.edid_firmware=Unknown-1:edid/1920x1080.bin" ];
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  security.sudo.wheelNeedsPassword = false;
  services.displayManager.sddm.settings.Autologin.Relogin = true;

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
