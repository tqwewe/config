{ inputs, ... }: {
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.x86_64-linux.default;

    settings = {
      theme = "nightfox";

      editor = {
        bufferline = "multiple";
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        idle-timeout = 200;
        indent-guides = {
          render = true;
          character = "╎";
        };
        line-number = "relative";
        lsp = {
          display-messages = true;
          auto-signature-help = false;
        };
        rulers = [120];
        statusline = {
          left = ["mode" "spinner" "version-control" "file-name"];
        };
        true-color = true;
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            newline = "none";
          };
        };
      };

      keys.normal = {
        "A-/" = "repeat_last_motion";
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";

        "X" = ["extend_line_up" "extend_to_line_bounds"];
        "A-x" = "extend_to_line_bounds";
      };

      keys.select = {
        "X" = ["extend_line_up" "extend_to_line_bounds"];
        "A-x" = "extend_to_line_bounds";
      };
    };
  };
}
