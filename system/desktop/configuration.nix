# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, config, ... }: {
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

  # Enable Gnome
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # Auto Login Fix
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;


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

  environment.sessionVariables = rec {
    CARGO_BIN = "$HOME/.cargo/bin";
    
    PATH = [ 
      "${CARGO_BIN}"
    ];
  };
}
