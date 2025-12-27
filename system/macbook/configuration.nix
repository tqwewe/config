{
  pkgs,
  ...
}:
{
  imports = [
    ../modules/secrets.nix
  ];

  environment = {
    shells = with pkgs; [ fish ];
    variables = { };
  };

  programs = {
    fish.enable = true;
  };

  users.users.ari = {
    name = "ari";
    home = "/Users/ari";
    shell = pkgs.fish;
  };

  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    config.allowUnfree = true;
  };

  nix.extraOptions = ''
    extra-experimental-features = nix-command flakes
  '';

  nix = {
    settings = {
      trusted-users = [
        "root"
        "ari"
      ];
    };
  };

  system.stateVersion = 4;
}
