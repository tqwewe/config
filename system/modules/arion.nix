{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.arion
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
}
