{ inputs, ... }: {
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.x86_64-linux.default;
    # package = inputs.unstable.legacyPackages.x86_64-linux.helix;
    # defaultEditor = true;

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
          # display-messages = true;
          # auto-signature-help = false;
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

    languages = {
      # language = [{
      #   name = "rust";
      #   formatter = { command = "leptosfmt"; args = ["--stdin" "--rustfmt"]; };
      # }];
      language-server.rust-analyzer.config = {
        cargo = {
          buildScripts.enable = true;
        };
        procMacro = {
          ignored = {
            leptos_macro = ["component" "server" "island"];
          };
        };
      };
      # language-server.rust-analyzer.config = {
      #   "rust-analyzer.rustfmt.overrideCommand" = ["sh" "-c" "rustfmt | leptosfmt --stdin"];
      # };
    };
  };
  home.sessionVariables = {
    EDITOR = "hx";
  };
}
