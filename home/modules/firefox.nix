{ pkgs, inputs, ... }: {
  programs.firefox = {
    enable = true;
    package = inputs.unstable.legacyPackages.x86_64-linux.firefox;

    profiles = {
      ari = {
        bookmarks = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "DuckDuckGo";
                tags = ["search"];
                keyword = "search";
                url = "https://duckduckgo.com/";
              }
              {
                name = "Youtube";
                tags = ["youtube"];
                keyword = "youtube";
                url = "https://www.youtube.com/";
              }
              {
                name = "Github";
                tags = ["github"];
                keyword = "github";
                url = "https://github.com/";
              }
              {
                name = "Email";
                tags = ["email"];
                keyword = "email";
                url = "https://outlook.live.com/mail/0/";
              }
              {
                name = "Nix";
                bookmarks = [
                  {
                    name = "Homepage";
                    url = "https://nixos.org/";
                  }
                  {
                    name = "Home Manager Options";
                    tags = ["homemanager"];
                    url = "https://mipmip.github.io/home-manager-option-search/";
                  }
                  {
                    name = "Packages Search";
                    url = "https://search.nixos.org/packages";
                  }
                  {
                    name = "Wiki";
                    tags = ["wiki" "nix"];
                    url = "https://nixos.wiki/";
                  }
                ];
              }
              {
                name = "Auctus";
                tags = ["auctus" "self-employment"];
                keyword = "auctus";
                url = "https://auctuslearning.anewspring.com.au/do?action=viewActivities&courseId=168";
              }
            ];
          }
        ];

        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          # https://nur.nix-community.org/repos/rycee/
          lastpass-password-manager
          return-youtube-dislikes
          sponsorblock
          ublock-origin
        ];
        
        isDefault = true;

        search = {
          default = "DuckDuckGo";
          force = true;
          order = [
            "DuckDuckGo"
            "Google"
          ];
        };
      };
    };
  };
}
