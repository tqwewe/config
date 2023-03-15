# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{
  imports = [
    ./hardware-configuration.nix

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
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;

  # Enable Plasma KDE
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "au";
  # services.xserver.displayManager.defaultSession = "plasmawayland"; # Wayland support
  
  # Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Users
  users.users = {
    ari = {
      initialPassword = "";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [];
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "ari";
}
