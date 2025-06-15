{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Hack Nerd Font Mono";
      package = pkgs.nerd-fonts.hack;
    };

    shellIntegration.enableFishIntegration = true;

    settings = {
      background_opacity = 0.98;
    };

    themeFile = "MaterialDark";
  };
}
