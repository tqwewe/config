{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.xpadneo.enable = true;

  environment.systemPackages = with pkgs; [
    protonup
  ];
}
