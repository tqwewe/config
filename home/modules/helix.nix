{ inputs, ... }: {
  programs.helix = {
    enable = true;
    package = inputs.unstable.legacyPackages.x86_64-linux.helix;

    settings = {
      theme = "onedark";

      editor = {
        line-number = "relative";
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides = {
          render = true;
          character = "╎";
        };
        lsp = {
          display-messages = true;
        };
        rulers = [ 120 ];
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            newline = "none";
          };
        };
      };
    };
  };
}
