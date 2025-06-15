{ pkgs, ... }:
{
  # Control monitor brightness from cli
  users.groups.i2c = { };
  services.udev.extraRules = ''
    # i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  environment.systemPackages = with pkgs; [
    ddcutil # Monitor brightness control cli
  ];
}
