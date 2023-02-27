# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    
    ../shared/base.nix
    ../shared/fish.nix
    ../shared/garbage.nix
    ../shared/locale.nix
  ];

  # Hostname
  networking.hostName = "server";

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  # SSH
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;

  # Users
  users.mutableUsers = false;
  users.users = {
    ari = {
      initialPassword = "";
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../key.pub)
      ];
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
  ];
}
