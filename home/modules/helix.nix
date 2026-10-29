{
  inputs,
  pkgs,
  ...
}:
let
  crates-lsp = pkgs.callPackage ../../pkgs/crates-lsp.nix { };
  # The moonbit toolchain swaps in nixpkgs' tinycc, whose installCheck test suite no
  # longer passes under GCC 16 (its reference compile rejects `int x[3] = { 1, 2, {{3}} }`
  # with "braces around scalar initializer"). tinycc itself builds fine, so take the
  # moonbit overlay against a pkgs where that self-test is skipped. Done here via a scoped
  # nixpkgs import rather than `inputs.moonbit-overlay.packages`, because the flake's own
  # package set evaluates with its own pkgs and would not see this override.
  moonbit-pkgs = import inputs.nixpkgs {
    inherit (pkgs) system;
    config.allowUnfree = true;
    overlays = [
      inputs.moonbit-overlay.overlays.default
      (_final: prev: {
        tinycc = prev.tinycc.overrideAttrs (_: { doInstallCheck = false; });
      })
    ];
  };
  # Temporarily disabled alongside the heklang flake input (missing locally).
  # The `hek` binary, for the `.hk` formatter below. heklang defines its own package, so
  # this takes it rather than describing how to build someone else's crate. `hek-grammar`
  # below comes from the same repository through a second input; `flake.nix` has why.
  # hek = inputs.heklang.packages.${pkgs.system}.hek;
  moonbit-grammar = pkgs.tree-sitter.buildGrammar {
    language = "moonbit";
    version = "unstable";
    src = inputs.tree-sitter-moonbit;
  };
  # Temporarily disabled alongside the tree-sitter-bsn flake input (missing locally).
  # bsn-grammar = pkgs.tree-sitter.buildGrammar {
  #   language = "bsn";
  #   version = "unstable";
  #   src = inputs.tree-sitter-bsn;
  # };
  # Temporarily disabled alongside the tree-sitter-hek flake input (missing locally).
  # hek-grammar = pkgs.tree-sitter.buildGrammar {
  #   language = "hek";
  #   version = "unstable";
  #   src = inputs.tree-sitter-hek;
  # };
  # Merge helix's bundled rust injections with a bsn injection so `bsn!`/`bsn_list!`
  # macro bodies get BSN highlighting. A user runtime queries file fully shadows the
  # bundled one, so we re-include the defaults and append the bsn rule last (last
  # match wins, overriding the generic rust token_tree injection).
  rust-injections = ''
    ${builtins.readFile "${inputs.helix}/runtime/queries/rust/injections.scm"}

    ; Inject BSN highlighting for bsn! and bsn_list! macros in Rust
    ((macro_invocation
        macro: (identifier) @_macro
        (token_tree) @injection.content)
      (#match? @_macro "^(bsn|bsn_list)$")
      (#set! injection.language "bsn"))
  '';
in
{
  programs.helix = {
    enable = true;
    package =
      (inputs.helix.packages.${pkgs.system}.helix.override {
        # GCC 16 (from the nixpkgs bump) defaults to gnu23, which switches on glibc 2.44's
        # type-generic `bsearch` macro. That collides with the plain `bsearch` several
        # tree-sitter scanners bundle (perl, php, pest, picat, ...), so grammar compilation
        # fails with "expected identifier or '(' before '_Generic'". Build every grammar as
        # C11 to keep the macro off; the editor itself still builds with the default stdenv.
        grammarOverlays = [
          (
            _final: prev:
            pkgs.lib.mapAttrs (
              _name: drv:
              if pkgs.lib.isDerivation drv then
                drv.overrideAttrs (o: { FLAGS = (o.FLAGS or [ ]) ++ [ "-std=gnu11" ]; })
              else
                drv
            ) prev
          )
        ];
      }).overrideAttrs
        (old: {
          cargoBuildFlags = (old.cargoBuildFlags or [ ]) ++ [
            "--features"
            "steel"
          ];
          buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.steel ]; # if steel lib is needed
        });

    settings = {
      theme = "nightfox";

      editor = {
        bufferline = "always";
        clipboard-provider = "termcode";
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
        rulers = [ 120 ];
        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
            "file-name"
          ];
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

        # https://github.com/sxyazi/yazi/pull/2461
        "C-y" = [
          ":sh rm -f /tmp/unique-file"
          ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
          '':insert-output echo "\x1b[?1049h\x1b[?2004h" > /dev/tty''
          ":open %sh{cat /tmp/unique-file}"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
        ];
      };

      keys.select = {
        "X" = "select_line_above";
        "A-x" = "extend_to_line_bounds";
      };
    };

    languages = {
      language = [
        {
          name = "html";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          formatter.args = [
            "--stdin-filepath"
            "%{buffer_name}"
          ];
          auto-format = true;
          language-servers = [ "vscode-html-language-server" ];
        }
        {
          name = "javascript";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          formatter.args = [
            "--stdin-filepath"
            "%{buffer_name}"
          ];
          auto-format = true;
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "jsx";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          formatter.args = [
            "--stdin-filepath"
            "%{buffer_name}"
          ];
          auto-format = true;
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "typescript";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          formatter.args = [
            "--parser"
            "typescript"
            "--stdin-filepath"
            "%{buffer_name}"
          ];
          auto-format = true;
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "tsx";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          formatter.args = [
            "--parser"
            "typescript"
            "--stdin-filepath"
            "%{buffer_name}"
          ];
          auto-format = true;
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "svelte";
          formatter.command = "${pkgs.prettier}/bin/prettier";
          # formatter.args = ["--parser" "typescript" "--stdin-filepath" "main.svelte"];
          formatter.args = [
            "--stdin-filepath"
            "main.svelte"
          ];
          auto-format = true;
          language-servers = [
            "svelteserver"
            {
              name = "tailwindcss-ls";
              except-features = [ "hover" ];
            }
            "vscode-eslint-language-server"
          ];
          comment-token = "//";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
        }
        {
          name = "toml";
          formatter = {
            command = "taplo";
            args = [
              "format"
              "-"
            ];
          };
          language-servers = [
            "taplo"
            "crates-lsp"
          ];
        }
        {
          name = "nix";
          formatter.command = "nixfmt";
          auto-format = true;
        }
        {
          name = "sql";
          formatter = {
            command = "${pkgs.sqlfluff}/bin/sqlfluff";
            args = [
              "format"
              "--dialect=postgres"
              "-"
            ];
          };
          auto-format = true;
        }
        {
          name = "starlark";
          formatter = {
            command = "${pkgs.bazel-buildtools}/bin/buildifier";
            args = [ "-path=%{buffer_name}" ];
          };
          auto-format = true;
        }
        {
          name = "markdown";
          soft-wrap = {
            enable = true;
            wrap-at-text-width = true;
          };
          text-width = 120;
        }
        {
          name = "moonbit";
          language-id = "moonbit";
          scope = "source.moonbit";
          injection-regex = "mbt|moonbit";
          file-types = [ "mbt" ];
          roots = [
            "moon.mod"
            "moon.mod.json"
            "moon.pkg.json"
          ];
          auto-format = true;
          comment-tokens = [
            "//"
            "///"
            "///|"
          ];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
          language-servers = [ "moonbit-lsp" ];
          grammar = "moonbit";
        }
        # Temporarily disabled: tree-sitter-bsn grammar is unavailable locally.
        # {
        #   name = "bsn";
        #   scope = "source.bsn";
        #   injection-regex = "bsn";
        #   file-types = [ "bsn" ];
        #   roots = [ ];
        #   auto-format = false;
        #   comment-token = "//";
        #   block-comment-tokens = {
        #     start = "/*";
        #     end = "*/";
        #   };
        #   indent = {
        #     tab-width = 2;
        #     unit = "  ";
        #   };
        #   grammar = "bsn";
        # }
        # Temporarily disabled: tree-sitter-hek grammar / hek binary unavailable locally.
        # {
        #   name = "hek";
        #   scope = "source.hek";
        #   injection-regex = "hek";
        #   file-types = [ "hk" ];
        #   roots = [ ];
        #   # `hek fmt -` reads one module on stdin and writes it back on stdout. On a module
        #   # that does not parse it exits non-zero with stdout empty, which is what makes
        #   # format-on-save safe: helix reports the error and keeps the buffer rather than
        #   # replacing it with nothing, so a half-typed file is never emptied.
        #   formatter.command = "${hek}/bin/hek";
        #   formatter.args = [
        #     "fmt"
        #     "-"
        #   ];
        #   auto-format = true;
        #   # hek has `//` and no block comment form, so there is nothing to pair here.
        #   comment-token = "//";
        #   indent = {
        #     tab-width = 2;
        #     unit = "  ";
        #   };
        #   grammar = "hek";
        # }
      ];

      language-server.crates-lsp = {
        command = "crates-lsp";
        except-featues = [ "format" ];
      };

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

      language-server.rust-analyzer = {
        config = {
          cargo = {
            buildScripts.enable = true;
            features = "all";
            allTargets = true;
          };

          check.command = "clippy";

          files = {
            excludeDirs = [
              ".git"
              "target"
              ".devenv"
              ".direnv"
              "node_modules"
              ".pnpm"
              "dist"
              "build"
              "result"
              ".next"
            ];
          };

          # procMacro = {
          #   ignored = {
          #     leptos_macro = [
          #       "component"
          #       "server"
          #       "island"
          #     ];
          #   };
          # };

          # "rust-analyzer.rustfmt.overrideCommand" = [
          #   "leptosfmt"
          #   "--stdin"
          #   "--rustfmt"
          # ];
        };
      };

      language-server.vscode-css-language-server.config = {
        provideFormatter = true;
        css = {
          validate.enable = true;
          lint.unknownAtRules = "ignore";
        };
      };

      language-server.moonbit-lsp = {
        command = "moonbit-lsp";
      };
    };
  };

  home.packages = with pkgs; [
    bazel-buildtools
    crates-lsp
    nil
    nixfmt
    vscode-langservers-extracted
    typescript-language-server
    prettier
    sqlfluff
    lua-language-server
    moonbit-pkgs.moonbit-bin.latest
    taplo
    terraform-ls
    yaml-language-server
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  xdg.configFile."helix/runtime/grammars/moonbit.so" = {
    source = "${moonbit-grammar}/parser";
    force = true;
  };
  xdg.configFile."helix/runtime/queries/moonbit" = {
    source = "${inputs.tree-sitter-moonbit}/queries";
    force = true;
  };
  # Temporarily disabled: tree-sitter-bsn grammar is unavailable locally.
  # xdg.configFile."helix/runtime/grammars/bsn.so" = {
  #   source = "${bsn-grammar}/parser";
  #   force = true;
  # };
  # xdg.configFile."helix/runtime/queries/bsn" = {
  #   source = "${inputs.tree-sitter-bsn}/queries";
  #   force = true;
  # };
  # Temporarily disabled: tree-sitter-hek grammar is unavailable locally.
  # xdg.configFile."helix/runtime/grammars/hek.so" = {
  #   source = "${hek-grammar}/parser";
  #   force = true;
  # };
  # xdg.configFile."helix/runtime/queries/hek" = {
  #   source = "${inputs.tree-sitter-hek}/queries";
  #   force = true;
  # };
  xdg.configFile."helix/runtime/queries/rust/injections.scm".text = rust-injections;

  xdg.configFile."helix/yazi-picker.sh".text = ''
    #!/usr/bin/env bash

    paths=$(yazi "$2" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

    if [[ -n "$paths" ]]; then
    	zellij action toggle-floating-panes
    	zellij action write 27 # send <Escape> key
    	zellij action write-chars ":$1 $paths"
    	zellij action write 13 # send <Enter> key
    else
    	zellij action toggle-floating-panes
    fi
  '';

  xdg.configFile."helix/init.scm".text = "
    (require \"oil/oil.scm\")
  ";
}
