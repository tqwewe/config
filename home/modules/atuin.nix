{
  programs.atuin = {
    enable = true;

    flags = [
      # enableFishIntegration defaults to true and rebinds ctrl-r *and*
      # up-arrow. Keeping up-arrow on fish's own per-directory history means
      # atuin only takes over the search that is deliberately invoked.
      "--disable-up-arrow"

      # 18.19 binds "?" at an empty prompt to `atuin ai inline`, which talks to
      # Atuin's hosted assistant (hub.atuin.sh). That is a proprietary cloud
      # service in the shell's hot path, and the whole point of self-hosting
      # the sync server is not to have one. It also steals a character that is
      # reasonable to type on its own.
      "--disable-ai"
    ];

    settings = {
      # A WireGuard-only vhost, so this resolves and syncs while the zion
      # tunnel is up and fails quietly otherwise. Atuin is local-first: the
      # history database and the search work regardless.
      sync_address = "https://atuin.tqwewe.com";
      auto_sync = true;
      sync_frequency = "10m";

      # The package is pinned by the flake, so a self-update nag is noise.
      update_check = false;
    };
  };
}
