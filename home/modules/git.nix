{
  programs.git = {
    enable = true;

    userEmail = "dev@tqwewe.com";
    userName = "Ari Seyhun";

    lfs.enable = true;

    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
