{ inputs, pkgs, config, ... }: {
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.system}.default;
    # package = inputs.unstable.legacyPackages.x86_64-linux.helix;
    # defaultEditor = true;

    settings = {
      theme = "nightfox";

      editor = {
        bufferline = "always";
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        # end-of-line-diagnostics = "hint";
        idle-timeout = 200;
        indent-guides = {
          render = true;
          character = "╎";
        };
        # inline-diagnostics = {
        #   cursor-line = "error";
        # };
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

        # "X" = ["extend_line_up" "extend_to_line_bounds"];
        "X" = "select_line_above";
        "A-x" = "extend_to_line_bounds";

        "C-y" = {
          "y" = ":sh zellij run -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh";
          "v" = ":sh zellij run -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh vsplit";
          "h" = ":sh zellij run -c -f -x 10% -y 10% --width 80% --height 80% -- bash ~/.config/helix/yazi-picker.sh hsplit";
        };
      };

      keys.select = {
        # "X" = ["extend_line_up" "extend_to_line_bounds"];
        "X" = "select_line_above";
        "A-x" = "extend_to_line_bounds";
      };
    };

    languages = {
      language = [
        {
          name = "javascript";
          formatter.command = "prettier";
          formatter.args = ["--stdin-filepath" "main.js"];
          auto-format = true;
          language-servers = ["typescript-language-server"];
        }
        {
          name = "jsx";
          formatter.command = "prettier";
          formatter.args = ["--stdin-filepath" "main.jsx"];
          auto-format = true;
          language-servers = ["typescript-language-server"];
        }
        {
          name = "typescript";
          formatter.command = "prettier";
          formatter.args = ["--parser" "typescript" "--stdin-filepath" "main.ts"];
          auto-format = true;
          language-servers = ["typescript-language-server"];
        }
        {
          name = "tsx";
          formatter.command = "prettier";
          formatter.args = ["--parser" "typescript" "--stdin-filepath" "main.tsx"];
          auto-format = true;
          language-servers = ["typescript-language-server"];
        }
        {
          name = "svelte";
          formatter.command = "prettier";
          # formatter.args = ["--parser" "typescript" "--stdin-filepath" "main.svelte"];
          formatter.args = ["--stdin-filepath" "main.svelte"];
          auto-format = true;
          language-servers = [
            "svelteserver"
            { name = "tailwindcss-ls"; except-features = ["hover"]; }
            "vscode-eslint-language-server"
          ];
          comment-token = "//";
          block-comment-tokens = { start = "/*"; end = "*/"; };
        }
        {
          name = "rust";
          language-servers = ["rust-analyzer"];
        }
      ];

      # language-server.gpt = {
      #   command = "bash";
      #   args = [
      #     "-c"
      #     ''
      #       /Users/ari/.deno/bin/deno run --allow-env --allow-net https://raw.githubusercontent.com/tqwewe/helix-gpt/refs/heads/deno/src/app.ts \
      #       --handler copilot \
      #       --copilotApiKey "$(cat ${config.age.secrets.copilotApiKey.path})"
      #     ''
      #   ];
      # };

      # language-server.deepseek = {
      #   command = "bash";
      #   args = [
      #     "-c"
      #     ''
      #       /Users/ari/.deno/bin/deno run --allow-env --allow-net https://raw.githubusercontent.com/tqwewe/helix-gpt/refs/heads/deno/src/app.ts \
      #       --handler openai \
      #       --openaiKey "$(cat ${config.age.secrets.deepseekApiKey.path})" \
      #       --openaiEndpoint "https://api.deepseek.com/v1/chat/completions" \
      #       --openaiModel "deepseek-chat"
      #     ''
      #   ];
      # };

      language-server.rust-analyzer.config = {
        cargo = {
          buildScripts.enable = true;
          features = "all";
        };
        check.command = "clippy";
        procMacro = {
          ignored = {
            leptos_macro = ["component" "server" "island"];
          };
        };
        "rust-analyzer.rustfmt.overrideCommand" = ["leptosfmt" "--stdin" "--rustfmt"];
      };

      language-server.vscode-css-language-server.config = {
        provideFormatter = true;
        css = {
          validate.enable = true;
          lint.unknownAtRules = "ignore";
        };
      };
    };
  };
  home.sessionVariables = {
    EDITOR = "hx";
  };
  xdg.configFile."helix/yazi-picker.sh".text = ''
    #!/usr/bin/env bash

    paths=$(yazi --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

    if [[ -n "$paths" ]]; then
    	zellij action toggle-floating-panes
    	zellij action write 27 # send <Escape> key
    	zellij action write-chars ":$1 $paths"
    	zellij action write 13 # send <Enter> key
    else
    	zellij action toggle-floating-panes
    fi
  '';
}
