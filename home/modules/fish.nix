{
  programs.fish = {
    enable = true;

    shellInit = ''
      set -gx GPG_TTY $(tty)
      set -gx EDITOR "hx"
      zoxide init fish | source

      if status is-login
        #if not set -q TMUX
        #  set -x TMUX tmux
        #  exec $TMUX
        #end
        if set -q ZELLIJ
        else
          zellij
        end
      end
    '';

    shellAliases = {
      cat = "bat";
      cd = "z";
      ls = "exa --long --group-directories-first --no-permissions --no-user";
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

      cr = ''
        if string match -q -e  -- "github.com" $argv[1]
          set -f owner (echo $argv | sed -e 's/.*github.com\/\([^\/]*\)\/.*/\1/g')
          set -f repo (echo $argv | sed -e 's/.*github.com\/[^\/]*\/\(.*\)\(\.git\)\?/\1/g')
          mkdir -p ~/dev/$owner > /dev/null
          git clone -- $argv[1] ~/dev/$owner/$repo
          cd ~/dev/$owner/$repo
        else
          if string match -q -e -- "/" $argv[1]
            set -f owner (echo $argv | sed -e 's/\([^\/]*\)\/.*/\1/g')
            set -f repo (echo $argv | sed -e 's/[^\/]*\/\(.*\)/\1/g')
            mkdir -p ~/dev/$owner > /dev/null
            gh repo clone $argv ~/dev/$owner/$repo
            cd ~/dev/$owner/$repo
          else
            set -f username (gh auth status 2>&1 | sed -n '2s/.*as \([^ ]*\).*/\1/p')
            set -f repo $argv[1]
            gh repo clone $argv ~/dev/$username/$repo
            cd ~/dev/$username/$repo
          end
        end
      '';
    };
  };
}
