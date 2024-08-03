# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, config, pkgs, ... }: {
  imports = [
    #inputs.nix-ld.nixosModules.nix-ld
    # ../modules/base.nix
    # ../modules/docker.nix
    # ../modules/fish.nix
    # ../modules/garbage.nix
    # ../modules/locale.nix
  ];

  environment.shells = with pkgs; [ fish ];
  programs.fish.enable = true;
  users.users.ari.shell = pkgs.fish;

  services.nix-daemon.enable = true;
  # Installs a version of nix, that dosen't need "experimental-features = nix-command flakes" in /etc/nix/nix.conf
  #services.nix-daemon.package = pkgs.nixFlakes;

  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    overlays = with inputs; [
      rust-overlay.overlays.default
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      permittedInsecurePackages = [
        "openssl-1.1.1v"
        "openssl-1.1.1w"
        "electron-24.8.6"
      ];
    };
  };

  nix.extraOptions = ''
    extra-experimental-features = nix-command flakes
  '';

  # Enable home-manager
  # programs.home-manager.enable = true;

  # Hostname
  # networking.hostName = "ari";
  # networking.networkmanager.enable = true;

  # environment.sessionVariables = rec {
  #   CARGO_BIN = "$HOME/.cargo/bin";
    
  #   PATH = [ 
  #     "${CARGO_BIN}"
  #   ];
  # };
  system.stateVersion = 4;
}
