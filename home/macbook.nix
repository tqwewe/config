{ inputs, pkgs, ... }:

let
  helix = inputs.helix.packages.x86_64-darwin.default;
  unstable = inputs.unstable.legacyPackages.x86_64-darwin;
in
{
  imports = with inputs; [
    agenix.homeManagerModules.default
    ../system/modules/secrets.nix

    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/neovim.nix
    ./modules/starship.nix
    ./modules/zellij.nix
  ];

  nixpkgs = {
    overlays = with inputs; [
      (final: prev: {
        zjstatus = zjstatus.packages.${prev.system}.default;
      })
    ];
  };

  home = {
    username = "ari";
    homeDirectory = "/Users/ari";
    sessionVariables = {
      EDITOR = "hx";
      BARTIB_FILE="/Users/ari/activities.bartib";
      # # Set macOS deployment target
      # MACOSX_DEPLOYMENT_TARGET = "11.3";
      # # Set rustflags to include proper linking arguments
      # RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";
      # # Point to the SDK
      # # SDKROOT = "${pkgs.darwin.apple_sdk.frameworks.CoreServices.out}/Library/Frameworks/CoreServices.framework/CoreServices";
      # SDKROOT = "${pkgs.darwin.apple_sdk.sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
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
    vscode-langservers-extracted
    unstable.yazi

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
