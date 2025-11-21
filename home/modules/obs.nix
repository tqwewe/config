{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      input-overlay
      obs-advanced-masks
      obs-backgroundremoval
      obs-shaderfilter
      obs-tuna
    ];
  };
}
