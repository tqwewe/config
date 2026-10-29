{ pkgs, ... }:
{
  environment.systemPackages = with pkgs.kdePackages; [
    plasma-bigscreen
    kdeconnect-kde # the bigscreen homescreen imports org.kde.kdeconnect and fails to load without it
  ];

  services.displayManager.sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];

  # plasma-bigscreen-inputhandler injects remote/CEC input via /dev/uinput, which its
  # udev rule opens up to the input group.
  services.udev.packages = [ pkgs.kdePackages.plasma-bigscreen ];
  users.users.ari.extraGroups = [ "input" ];
}
