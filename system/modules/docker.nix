{
  virtualisation.docker = {
    enable = true;
    liveRestore = false; # Not compatible with docker swarm
  };
  hardware.nvidia-container-toolkit.enable = true;
  users.extraGroups.docker.members = [ "ari" ];
  networking.firewall.trustedInterfaces = [
    "docker"
    "docker0"
  ];
  networking.firewall.allowedTCPPorts = [ 3000 ];
}
