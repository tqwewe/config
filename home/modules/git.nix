{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        email = "dev@tqwewe.com";
        name = "Ari Seyhun";
      };

      init.defaultBranch = "main";

      gpg = {
        format = "ssh";
        ssh = {
          program = "${pkgs.openssh}/bin/ssh-keygen";
        };
      };
    };

    lfs.enable = true;

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}
