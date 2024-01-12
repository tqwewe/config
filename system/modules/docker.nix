{
  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false; # Not compatible with docker swarm
  users.extraGroups.docker.members = [ "ari" ];
  networking.firewall.trustedInterfaces = [ "docker" "docker0" ];
  networking.firewall.allowedTCPPorts = [ 3000 ];
}
