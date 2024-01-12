# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ config, pkgs, lib, ... }: {
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    
    ../modules/base.nix
    ../modules/docker.nix
    ../modules/fish.nix
    ../modules/garbage.nix
    ../modules/locale.nix
    ../modules/networking.nix
  ];

  # Hostname
  networking.hostName = "server";

  # Bootloader
  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = false;
  networking.hostName = "cloud-dev";
  networking.domain = "";
  # networking.firewall.allowedTCPPorts = [ 80 443 465 587 25 993 143 8096, 3000 ];
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpecxt7TBNV6HlkVhdUNw3ntFpe6RA1f378XPHCOMeb ariseyhun@live.com.au'' ];

  # Users
  users.users = {
    ari = {
      initialPassword = "";
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "docker" ];
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # git
  ];

  environment.sessionVariables = rec {
    CARGO_BIN = "$HOME/.cargo/bin";
    
    PATH = [ 
      "${CARGO_BIN}"
    ];
  };
}
