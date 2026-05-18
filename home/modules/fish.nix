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
      set -gx BARTIB_FILE ~/.bartib/activities.bartib

      zoxide init fish | source

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

      jj = ''
        if test "$argv[1]" = "commit" && not contains -- --message $argv && not contains -- -m $argv
            # Extract path arguments (non-flag args after "commit")
            set paths
            for arg in $argv[2..]
                if not string match -q -- '-*' $arg
                    set -a paths $arg
                end
            end

            # Diff only the specified paths, or everything if none given
            if test (count $paths) -gt 0
                set diff (command jj diff --git $paths)
            else
                set diff (command jj diff --git)
            end

            if test -z "$diff"
                command jj $argv
                return
            end

            echo "Generating commit message..."

            set recent_commits (command jj log -n 10 --no-graph -T 'description ++ "\n"' 2>/dev/null | string trim)

            # Build context string mentioning specific files if applicable
            if test (count $paths) -gt 0
                set files_context "This commit covers only these paths: "(string join ", " $paths)". "
            else
                set files_context ""
            end

            set message (printf 'Diff:\n%s\n\nRecent commits for style reference:\n%s' $diff $recent_commits \
                | claude -p \
                $files_context"Generate a concise conventional commit message for this diff. \
                Match the style and scope conventions shown in the recent commits. \
                Output ONLY the commit message, no explanation, no fenced code blocks, no surrounding quotes. \
                Backticks around code identifiers, function names, or flags are fine." \
                --output-format text 2>/dev/null | string trim)

                if test -z "$message"
                echo "⚠ Could not generate message, falling back to interactive commit"
                command jj $argv
                return
            end

            echo "$message"
            read --prompt-str "Commit with this message? [Y/n/e(dit)] " confirm
            if test $status -ne 0
                echo "Aborted."
                return 1
            end

            switch $confirm
                case "" Y y
                    command jj commit -m $message $paths
                case e E
                    # Let them edit it
                    set edited (echo $message | vipe 2>/dev/null; or read --prompt-str "Edit: " --command-line $message)
                    command jj commit -m $edited $paths
                case '*'
                    echo "Aborted. Use 'jj commit -m \"your message\"' to commit manually."
            end
        else
            command jj $argv
        end
      '';

      setup-rust-env = ''
        devenv init
        and echo '{ languages.rust.enable = true; }' > devenv.nix
        and exec devenv shell fish
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
