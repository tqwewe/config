{
  nixpkgs.config.allowUnfree = true;

  fonts.fontconfig.enable = true;

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
