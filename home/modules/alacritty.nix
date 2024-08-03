{
  programs.alacritty = {
    enable = true;
    
    settings = {
      font = {
        size = 12.0;
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Light";
        };
        bold = {
          family = "FiraCode Nerd Font Mono";
          style = "Medium";
        };
        italic = {
          family = "FiraCode Nerd Font Mono";
          style = "Regular";
        };
      };
      window.option_as_alt = "Both";
    };
  };
}
