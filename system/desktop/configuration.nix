# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix

    inputs.nix-ld.nixosModules.nix-ld
    # ../modules/arion.nix
    ../modules/base.nix
    ../modules/docker.nix
    ../modules/fish.nix
    ../modules/garbage.nix
    ../modules/locale.nix
    ../modules/pipewire.nix
  ];

  # Hostname
  networking.hostName = "ari";
  networking.networkmanager.enable = true;

  # Bootloader
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;

  # Kernel Packages
  boot.extraModulePackages = with config.boot.kernelPackages; [ perf ];

  # NUR
  nixpkgs.config.packageOverrides = {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # Enable Gnome
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # Auto Login Fix
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Webcam
  # boot.extraModprobeConfig = ''
  #   v4l2loopback devices=2 video_nr=4,5 card_label="OBS,GoPro"
  # '';
  systemd.services.webcam = {
    path = with pkgs; [v4l-utils ffmpeg_5-full kmod];
    wantedBy = ["multi-user.target"];
    script = ''
      modprobe -r v4l2loopback
      modprobe v4l2loopback devices=2 video_nr=4,5 card_label="OBS,GoPro"
      ffmpeg -f v4l2 -input_format mjpeg -r 30 -i /dev/video1 -vcodec rawvideo -pix_fmt rgb24 -r 30 -f v4l2 /dev/video5
    '';
  };
  
  # Enable Plasma KDE
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.layout = "au";
  # # services.xserver.displayManager.defaultSession = "plasmawayland"; # Wayland support
  
  # Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

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
      openssh.authorizedKeys.keys = [];
      extraGroups = [ "networkmanager" "wheel" "docker" ];
    };
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "ari";

  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  environment.sessionVariables = rec {
    CARGO_BIN = "$HOME/.cargo/bin";
    
    PATH = [ 
      "${CARGO_BIN}"
    ];
  };
}
