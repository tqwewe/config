{ inputs, lib, config, pkgs, ... }: {
  # Fish shell
  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [ fish ];
  programs.fish.enable = true;
}
