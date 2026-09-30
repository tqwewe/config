{
  programs.atuin = {
    enable = true;

    # enableFishIntegration defaults to true and rebinds ctrl-r *and* up-arrow.
    # Keeping up-arrow on fish's own per-directory history means atuin only
    # takes over the search that is deliberately invoked.
    flags = [ "--disable-up-arrow" ];

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
