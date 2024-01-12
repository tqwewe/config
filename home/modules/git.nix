{
  programs.git = {
    enable = true;

    userEmail = "ariseyhun@live.com.au";
    userName = "Ari Seyhun";

    lfs.enable = true;
    
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
