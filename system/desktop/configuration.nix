{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix

    ../modules/base.nix
    ../modules/brightness-control.nix
    ../modules/fish.nix
    ../modules/gnome.nix
    # ../modules/greetd.nix
    # ../modules/hyprland.nix
    # ../modules/kde.nix
    ../modules/locale.nix
    ../modules/nh.nix
    ../modules/nvidia.nix
    ../modules/pipewire.nix
    ../modules/steam.nix
  ];

  # Hostname
  networking.hostName = "desktop";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GSConnect ports
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1716;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1716;
        to = 1764;
      }
    ];
  };

  # Open WebUI
  services.open-webui.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.resumeDevice = "/dev/disk/by-uuid/6d614528-903b-4eba-8179-927f7d50ec2f";
  powerManagement.enable = true;
  boot.kernel.sysctl = {
    # Queue management for low latency
    "net.core.default_qdisc" = "cake";

    # Socket buffer limits (moderate sizes for gaming)
    "net.core.rmem_max" = 4194304; # 4MB max receive buffer
    "net.core.wmem_max" = 4194304; # 4MB max send buffer
    "net.core.rmem_default" = 262144; # 256KB default receive
    "net.core.wmem_default" = 262144; # 256KB default send

    # TCP buffer sizes (min, default, max)
    "net.ipv4.tcp_rmem" = "8192 262144 4194304"; # 8KB, 256KB, 4MB
    "net.ipv4.tcp_wmem" = "8192 262144 4194304"; # 8KB, 256KB, 4MB

    # Gaming-specific optimizations
    "net.ipv4.tcp_congestion_control" = "bbr"; # Better congestion control
    "net.ipv4.tcp_slow_start_after_idle" = 0; # Don't slow down after idle
    "net.core.netdev_max_backlog" = 5000; # Handle packet bursts
    "net.ipv4.tcp_mtu_probing" = 1; # Enable MTU discovery

    "vm.max_map_count" = 2147483642;
  };
  # boot.kernel.sysctl = {
  #   # Increase network buffers significantly
  #   "net.core.rmem_max" = 134217728; # 128MB
  #   "net.core.wmem_max" = 134217728; # 128MB
  #   "net.core.rmem_default" = 262144; # 256KB
  #   "net.core.wmem_default" = 262144; # 256KB

  #   # TCP buffer tuning
  #   "net.ipv4.tcp_rmem" = "4096 87380 134217728";
  #   "net.ipv4.tcp_wmem" = "4096 65536 134217728";

  #   # Better congestion control for gaming
  #   "net.ipv4.tcp_congestion_control" = "bbr";
  #   "net.core.default_qdisc" = "fq";

  #   # Reduce bufferbloat
  #   "net.ipv4.tcp_low_latency" = 1;
  # };
  boot.supportedFilesystems = [ "ntfs" ];

  security.polkit.enable = true;

  # Kernel Packages
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
    perf
  ];
  # This will enable additional firmware blobs
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 11n_disable=8 bt_coex_active=0 swcrypto=1
    options iwlmvm power_scheme=1
  '';
  # options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
  # boot.extraModprobeConfig = ''
  #   options iwlwifi power_save=0 11n_disable=8 bt_coex_active=0 swcrypto=1
  #   options iwlmvm power_scheme=1
  # '';

  boot.postBootCommands = ''
    # Pin ALL WiFi interrupts to cores 1,2 only
    for irq in {171..186}; do
      echo 6 > /proc/irq/$irq/smp_affinity 2>/dev/null || true
    done
  '';

  # NUR
  nixpkgs.config.packageOverrides = {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  # Users
  users.users = {
    ari = {
      initialPassword = "";
      isNormalUser = true;
      description = "Ari Seyhun";
      openssh.authorizedKeys.keys = [ ];
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "i2c"
        "video"
      ];
    };
  };

  # Control monitor brightness from cli
  users.groups.i2c = { };
  services.udev.extraRules = ''
    # i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"

    # Disable built-in CNVi WiFi at PCI slot 00:14.3
    # ACTION=="add", SUBSYSTEM=="pci", KERNELS=="0000:00:14.3", ATTR{vendor}=="0x8086", RUN+="/bin/sh -c 'echo 1 > /sys/%p/remove'"

    # Disable Intel Wi-Fi 6 AX200 at PCI slot 07:00.0
    ACTION=="add", SUBSYSTEM=="pci", KERNELS=="0000:07:00.0", ATTR{vendor}=="0x8086", RUN+="/bin/sh -c 'echo 1 > /sys/%p/remove'"

    # Disable WiFi power management for gaming
    # ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/bin/sh -c 'echo on > /sys/class/net/%k/power/control'"
  '';
  systemd.services.disable-wifi-powersave = {
    description = "Disable WiFi power saving for gaming";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      sleep 5  # Give networking time to settle
      for iface in /sys/class/net/wl*/power/control; do
        if [ -e "$iface" ]; then
          echo on > "$iface"
        fi
      done
    '';
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ari";

  # Fix gnome auto login https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.upower = {
    enable = true;
  };
}
