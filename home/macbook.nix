{ inputs, pkgs, ... }:

let
  unstable = inputs.unstable.legacyPackages.x86_64-darwin;
in
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

  _module.args = {
    inherit unstable;
  };

  nixpkgs = {
    overlays = with inputs; [
      (final: prev: {
        zjstatus = zjstatus.packages.${prev.system}.default;
      })
      nh.overlays.default
    ];
  };

  home = {
    username = "ari";
    homeDirectory = "/Users/ari";
    sessionVariables = {
      EDITOR = "hx";
      BARTIB_FILE="/Users/ari/activities.bartib";
    };
  };

  # User programs & packages
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.eza.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    bartib
    helix-gpt
    nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript-language-server
    pkg-config
    ripgrep
    unstable.nodePackages.svelte-language-server
    tailwindcss-language-server
    taplo
    vscode-langservers-extracted
    unstable.yazi

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
