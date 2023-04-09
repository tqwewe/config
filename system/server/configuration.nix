# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ config, pkgs, lib, ... }: {
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    
    ../modules/base.nix
    ../modules/fish.nix
    ../modules/garbage.nix
    ../modules/jellyfin.nix
    ../modules/locale.nix
    ../modules/mailserver.nix
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

  # Roundcube
  services.roundcube = {
     enable = true;
     # this is the url of the vhost, not necessarily the same as the fqdn of
     # the mailserver
     hostName = "webmail.theari.dev";
     extraConfig = ''
       # starttls needed for authentication, so the fqdn required to match
       # the certificate
       $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
       $config['smtp_user'] = "%u";
       $config['smtp_pass'] = "%p";
     '';
  };

  services.nginx.enable = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 465 587 25 993 143 8096, 3000 ];

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
