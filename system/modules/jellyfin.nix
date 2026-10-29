{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.jellyfin.environment = {
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  users.users.jellyfin.extraGroups = [ "video" "render" ];

  environment.systemPackages = with pkgs; [
    jellyfin-ffmpeg
  ];
}
