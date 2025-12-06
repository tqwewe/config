{ pkgs, ... }:
let
  username = "tqwewe";
  cache_mins = 60;
in
{
  home.packages = with pkgs; [
    gh
    jq
  ];

  programs.fish = {
    functions = {
      # Function to clone GitHub repositories into ~/dev/{owner}/{repo} directory.
      # Usage: cr owner/repo
      # Also handles: cr https://github.com/owner/repo.git
      #               cr git@github.com:owner/repo.git
      #               cr repo # uses currently logged in users repo
      cr = {
        description = "Clone a GitHub repo via URL or owner/repo or repo";
        body = ''
          __parse_repo $argv[1]

          mkdir -p ~/dev/$repo_owner

          if test $repo_is_url = 1
            git clone -- $argv[1] ~/dev/$repo_owner/$repo_name
          else
            gh repo clone $repo_owner/$repo_name ~/dev/$repo_owner/$repo_name
          end

          cd ~/dev/$repo_owner/$repo_name
        '';
      };

      __parse_repo = {
        description = "Parse GitHub repo argument";
        body = ''
          set -l arg "$argv[1]"

          # URL case: HTTPS or SSH
          if string match -qr '^(https://github\.com/|git@github\.com:)' -- "$arg"
            set -g repo_is_url 1

            # Remove protocol prefix
            set -l no_proto (string replace -r '^(https://github\.com/|git@github\.com:)' \'\' -- "$arg")
            # Remove trailing .git
            set -l trimmed (string replace -r '\.git$' \'\' -- "$no_proto")

            set -g repo_owner (string split '/' "$trimmed")[1]
            set -g repo_name  (string split '/' "$trimmed")[2]
            return
          end

          # "owner/repo"
          if string match -qr '/' -- "$arg"
            set -g repo_is_url 0
            set -g repo_owner (string split '/' "$arg")[1]
            set -g repo_name  (string split '/' "$arg")[2]
            return
          end

          # Bare "repo"
          set -g repo_is_url 0
          set -l username (gh api user --jq '.login' 2>/dev/null)

          if test -z "$username"
            set username (gh auth status --hostname github.com 2>&1 | sed -n 's/.*as \([^ ]*\).*/\1/p')
          end

          if test -z "$username"
            set username "${username}"
          end

          set -g repo_owner "$username"
          set -g repo_name  "$arg"
        '';
      };

      __cr_completion = ''
        set -l input (commandline -ct)

        # Parse the input
        __parse_repo $input

        # If input is a URL, don't provide completions
        if test $repo_is_url = 1
          return
        end

        # Return early if we couldn't determine owner
        test -n "$repo_owner"; or return

        # Determine if we should prefix completions with owner/
        set -l prefix ""
        if string match -qr '/' -- $input
          set prefix "$repo_owner/"
        end

        # Cache management
        mkdir -p ~/.cache/fish
        set -l cache_file ~/.cache/fish/cr_repos_$repo_owner

        set -l needs_refresh false
        if test -f $cache_file
          # Check if cache is older than 1 hour (60 minutes)
          set -l stale_cache (find $cache_file -mmin +${toString cache_mins} 2>/dev/null)
          if test -n "$stale_cache"
            set needs_refresh true
          end
        else
          # No cache exists - start creating it in background (non-blocking)
          # Use fish_pid to ensure unique background job
          if not jobs -q
            gh search repos --json name --jq '.[].name' --owner $repo_owner >$cache_file 2>/dev/null &
          end
          # Return no completions on first trigger - cache will be ready next time
          return
        end

        # Show completions from cache
        if test -f $cache_file
          for repo in (cat $cache_file)
            # Filter by repo_name if it exists
            if test -z "$repo_name"
              echo "$prefix$repo"
            else if string match -qi "*$repo_name*" -- $repo
              echo "$prefix$repo"
            end
          end
        end

        # Refresh stale cache in background
        if test "$needs_refresh" = true
          gh search repos --json name --jq '.[].name' --owner $repo_owner >$cache_file 2>/dev/null &
        end
      '';
    };

    completions = {
      cr = ''
        complete -c cr -f -a '(__cr_completion)'
      '';
    };
  };
}
