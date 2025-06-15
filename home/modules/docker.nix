{ pkgs, ... }:
{
  home.packages = with pkgs; [
    docker-compose
    kubernetes
    lazydocker
  ];
}
