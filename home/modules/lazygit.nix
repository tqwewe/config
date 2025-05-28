{
  programs.lazygit = {
    enable = true;

    settings = {
      git.paging = {
        colorArg = "always";
        pager = "delta --dark --paging=never";
      };
    };
  };
  programs.git.delta.enable = true;
}
