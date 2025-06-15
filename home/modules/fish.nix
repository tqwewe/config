{
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
    '';

    shellAliases = {
      cat = "bat";
      ls = "exa --long --group-directories-first --no-permissions --no-user";
      rustdev = "nix develop ~/dev/tqwewe/config#rust -c fish";
    };

    functions = {
      fish_greeting = ''
        # echo Hello Ari!
        # echo The time is (set_color yellow; date +%T; set_color normal)
      '';

      fish_user_key_bindings = ''
        bind \e\[1\;5D backward-word
        bind \e\[1\;5C forward-word
        bind \b backward-kill-word
      '';

      cd = ''
        z $argv
        if test $status -eq 0
          # Configure the prefix for auto-generated tab names
          set prefix "*"

          # Get current tab name
          set current_tab_name (zellij action dump-layout 2>/dev/null | grep "tab name=.*focus=true" | sed 's/.*name="\([^"]*\)".*/\1/')

          # Check if it's a default tab name OR an auto-generated one with our prefix
          # Use string match with literal matching (not glob patterns)
          if string match -qr '^Tab #[0-9]+$' "$current_tab_name"; or test (string sub --length (string length "$prefix") "$current_tab_name") = "$prefix"
            set current_dir (basename $PWD)
            zellij action rename-tab "$prefix$current_dir" 2>/dev/null
          end
        end
      '';

      # Function to clone GitHub repositories into ~/dev/{owner}/{repo} directory.
      # Usage: cr owner/repo
      # Also handles: cr https://github.com/owner/repo.git
      #               cr git@github.com:owner/repo.git
      #               cr repo # uses currently logged in users repo
      cr = ''
        set -l repo_arg $argv[1]

        # Handle GitHub URLs (both HTTPS and SSH)
        if string match -q -r -- "(https://github.com/|git@github.com:)" $repo_arg
            # Extract owner/repo from HTTPS URL: https://github.com/owner/repo.git
            # or from SSH URL: git@github.com:owner/repo.git
            set -l repo_path (echo $repo_arg | sed -E 's/^(https:\/\/github\.com\/|git@github\.com:)([^\/]+)\/([^\/]+)(\.git)?$/\2\/\3/g')

            # Extract owner and repo from the path
            set -l owner (echo $repo_path | cut -d '/' -f 1)
            set -l repo (echo $repo_path | cut -d '/' -f 2 | sed 's/\.git$//')

            # Create directory if it doesn't exist
            mkdir -p ~/dev/$owner > /dev/null

            # Clone repository
            git clone -- $repo_arg ~/dev/$owner/$repo
            cd ~/dev/$owner/$repo
        else
            # Handle simple "owner/repo" format
            if string match -q -r -- "/" $repo_arg
                set -l owner (echo $repo_arg | cut -d '/' -f 1)
                set -l repo (echo $repo_arg | cut -d '/' -f 2)

                mkdir -p ~/dev/$owner > /dev/null
                gh repo clone $repo_arg ~/dev/$owner/$repo
                cd ~/dev/$owner/$repo
            else
                # Handle just "repo" format (uses current GitHub username)
                # More reliable way to get GitHub username
                set -l username (gh api user --jq '.login' 2>/dev/null)

                # Fallback if API call fails
                if test -z "$username"
                    set username (gh auth status --hostname github.com 2>&1 | grep "Logged in" | sed -n 's/.*as \([^ ]*\).*/\1/p')
                end

                # Final fallback - hardcode your username
                if test -z "$username"
                    set username "tqwewe"
                end

                set -l repo $repo_arg

                mkdir -p ~/dev/$username
                cd ~/dev/$username
                gh repo clone $username/$repo
                cd $repo
            end
        end
      '';

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
    };
  };
}
