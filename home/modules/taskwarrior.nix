{ pkgs, config, ... }:
{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      "hooks.location" = "${config.xdg.configHome}/task/hooks";
      dateformat = "D-M-Y";
      "dateformat.holiday" = "DMY";
      "dateformat.edit" = "D-M-Y H:N:S";
      "dateformat.info" = "D-M-Y H:N:S";
      # Disable news (https://taskwarrior.org/docs/man/taskrc.5/)
      verbose = "blank,header,footnote,label,new-id,affected,edit,special,project,sync,override,recur";
    };
  };

  home.packages = with pkgs; [ taskwarrior-tui ];
}
