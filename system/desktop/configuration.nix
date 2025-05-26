{ inputs, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix

    ../modules/base.nix
    ../modules/docker.nix
    ../modules/fish.nix
    ../modules/garbage.nix
    ../modules/locale.nix
    ../modules/nvidia.nix
    ../modules/pipewire.nix
  ];

  # Hostname
  networking.hostName = "pc";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "quiet" ];
  boot.kernel.sysctl = {
    # Increase network buffers significantly
    "net.core.rmem_max" = 134217728;      # 128MB
    "net.core.wmem_max" = 134217728;      # 128MB
    "net.core.rmem_default" = 262144;     # 256KB
    "net.core.wmem_default" = 262144;     # 256KB
    
    # TCP buffer tuning
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    
    # Better congestion control for gaming
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    
    # Reduce bufferbloat
    "net.ipv4.tcp_low_latency" = 1;
  };

  security.polkit.enable = true;

  # Kernel Packages
  boot.extraModulePackages = with config.boot.kernelPackages; [ perf ];
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 bt_coex_active=0 uapsd_disable=1 11n_disable=1 amsdu_size=0 fw_restart=0 disable_11ax=1
    options iwlmvm power_scheme=1
  '';

  powerManagement.cpuFreqGovernor = "performance";

  # NUR
  nixpkgs.config.packageOverrides = {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time  --cmd Hyprland";
        user = "ari";
      };
    };
  };

  # Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Users
  users.users = {
    ari = {
      initialPassword = "";
      isNormalUser = true;
      description = "Ari Seyhun";
      openssh.authorizedKeys.keys = [];
      extraGroups = [ "networkmanager" "wheel" "docker" "i2c" ];
    };
  };

  # Control monitor brightness from cli
  users.groups.i2c = {};
  services.udev.extraRules = ''
    # i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"

    # Disable built-in CNVi WiFi at PCI slot 00:14.3
    ACTION=="add", SUBSYSTEM=="pci", KERNELS=="0000:00:14.3", ATTR{vendor}=="0x8086", RUN+="/bin/sh -c 'echo 1 > /sys/%p/remove'"

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

  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    protonup
    ddcutil # Monitor brightness control cli
  ];

  environment.sessionVariables = rec {
    CARGO_BIN = "$HOME/.cargo/bin";
    
    PATH = [ 
      "${CARGO_BIN}"
    ];
  };
}
