{ inputs, pkgs, ... }:
{
  imports = with inputs; [
    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/nh.nix
    ./modules/starship.nix
    ./modules/zellij.nix

    # Secrets
    agenix.homeManagerModules.default
    ../system/modules/secrets.nix
  ];

  home = {
    username = "ari";
    homeDirectory = "/Users/ari";
    sessionVariables = {
      EDITOR = "hx";
      BARTIB_FILE = "/Users/ari/activities.bartib";
      XDG_CONFIG_HOME = "/Users/ari/.config";
    };
  };

  # User programs & packages
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.eza.enable = true;
  programs.zoxide.enable = true;

  home.packages =
    with pkgs;
    [
      bartib
      claude-code
      devenv
      helix-gpt
      nodejs
      nodePackages.vscode-langservers-extracted
      nodePackages.typescript-language-server
      pkg-config
      ripgrep
      nodePackages.svelte-language-server
      tailwindcss-language-server
      taplo
      vscode-langservers-extracted
      yazi
    ]
    ++ (with nerd-fonts; [
      # Fonts
      droid-sans-mono
      fira-code
      hack
      noto
    ]);
}
