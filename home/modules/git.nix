{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;

    userEmail = "dev@tqwewe.com";
    userName = "Ari Seyhun";

    lfs.enable = true;

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";

      gpg = {
        format = "ssh";
        ssh = {
          program = "${pkgs.openssh}/bin/ssh-keygen";
        };
      };
    };
  };
}
