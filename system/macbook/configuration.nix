{ inputs, config, pkgs, ... }: {
  imports = [
    ../modules/secrets.nix
  ];

  environment = {
    shells = with pkgs; [ fish ];
    variables = {};
  };

  programs = {
    fish.enable = true;
  };

  users.users.ari.shell = pkgs.fish;

  services.nix-daemon.enable = true;

  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    config.allowUnfree = true;
  };

  nix.extraOptions = ''
    extra-experimental-features = nix-command flakes
  '';

  system.stateVersion = 4;
}
