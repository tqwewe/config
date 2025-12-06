{
  imports = [
    ./fish-cr.nix
  ];

  programs.fish = {
    enable = true;

    shellInit = ''
      set -gx GPG_TTY $(tty)
      set -gx EDITOR "hx"
      set -gx PATH $PATH ~/.cargo/bin
      set -gx ZELLIJ_AUTO_ATTACH true
      set -gx BARTIB_FILE ~/.bartib/activities.bartib
      # set -gx DYLD_FALLBACK_LIBRARY_PATH /usr/lib $DYLD_FALLBACK_LIBRARY_PATH
      # set -gx LIBRARY_PATH /usr/lib $LIBRARY_PATH
      # set -gx RUSTFLAGS "-L/usr/lib $RUSTFLAGS"

      zoxide init fish | source

      if status is-interactive
        eval (zellij setup --generate-auto-start fish | string collect)
      end

      if command -q nix-shell
        complete -c nix-shell -f -a "(__nix_packages)"
      end
    '';

    shellAliases = {
      cat = "bat";
      cd = "z";
      ls = "exa --long --group-directories-first --no-permissions --no-user";
      rustdev = "nix develop ~/dev/tqwewe/config#rust -c fish";
    };

    functions = {
      __nix_packages = ''
        if not set -q __nix_package_cache
          set -g __nix_package_cache (nix eval --raw --impure --expr 'builtins.concatStringsSep "\n" (builtins.attrNames (import <nixpkgs> {}))' 2>/dev/null)
        end
        printf '%s\n' $__nix_package_cache | string match '*'(commandline -ct)'*'
      '';

      fish_greeting = ''
        # echo Hello Ari!
        # echo The time is (set_color yellow; date +%T; set_color normal)
      '';

      fish_title = ''
        set -l title

        # If we're connected via ssh, we print the hostname.
        set -l ssh
        set -q SSH_TTY
        and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"
        # An override for the current command is passed as the first parameter.
        # This is used by `fg` to show the true process name, among others.
        if set -q argv[1]
            set title $ssh (string sub -l 20 -- $argv[1]) (prompt_pwd -d 1 -D 1)
        else
            # Don't print "fish" because it's redundant
            set -l command (status current-command)
            if test "$command" = fish
                set command
            end
            set title $ssh (string sub -l 20 -- $command) (prompt_pwd -d 1 -D 1)
        end

        if set -q ZELLIJ
            zellij action rename-tab "$title"
        end
        echo "$title"
      '';

      fish_user_key_bindings = ''
        bind \e\[1\;5D backward-word
        bind \e\[1\;5C forward-word
        bind \b backward-kill-word
      '';

      # cd = ''
      #   z $argv
      #   if test $status -eq 0
      #     # Configure the prefix for auto-generated tab names
      #     set prefix "*"

      #     # Get current tab name
      #     set current_tab_name (zellij action dump-layout 2>/dev/null | grep "tab name=.*focus=true" | sed 's/.*name="\([^"]*\)".*/\1/')

      #     # Check if it's a default tab name OR an auto-generated one with our prefix
      #     # Use string match with literal matching (not glob patterns)
      #     if string match -qr '^Tab #[0-9]+$' "$current_tab_name"; or test (string sub --length (string length "$prefix") "$current_tab_name") = "$prefix"
      #       set current_dir (basename $PWD)
      #       zellij action rename-tab "$prefix$current_dir" 2>/dev/null
      #     end
      #   end
      # '';

      setup-rust-env = ''
        # Create the .envrc file
        echo 'use flake ~/dev/tqwewe/config#rust' > ./.envrc
        echo "Created .envrc file"

        # Allow the .envrc file with direnv
        direnv allow

        # Check if .gitignore exists
        if test -f .gitignore
          # Check if .direnv is already in .gitignore
          if not grep -q '\.direnv' .gitignore
            # Add .direnv to .gitignore
            echo ".direnv" >> .gitignore
            echo "Added .direnv to .gitignore"
          else
            echo ".direnv already in .gitignore"
          end

          # Check if .envrc is already in .gitignore
          if not grep -q '\.envrc' .gitignore
            # Add .envrc to .gitignore
            echo ".envrc" >> .gitignore
            echo "Added .envrc to .gitignore"
          else
            echo ".envrc already in .gitignore"
          end
        else
          echo "No .gitignore found, skipping .gitignore update"
        end

        echo "Rust environment setup complete!"
      '';

      rusttemp = ''
        if test (count $argv) -lt 1
          echo "Usage: rusttemp <project-name>"
          return 1
        end

        set project_name $argv[1]
        set project_dir /tmp/$project_name

        if test -d $project_dir
          echo "Error: $project_dir already exists."
          return 1
        end

        mkdir $project_dir
        and cd $project_dir
        and devenv init
        and echo '{ languages.rust.enable = true; }' > devenv.nix
        and devenv shell cargo init --bin
        and exec devenv shell fish
      '';
    };
  };
}
