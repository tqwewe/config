{ config, lib, ... }:
{
  users.groups.media = { };

  users.users = {
    ari.extraGroups = [ "media" ];
    radarr.extraGroups = [ "media" ];
    sonarr.extraGroups = [ "media" ];
    jellyfin.extraGroups = [ "media" ];
    qbittorrent.extraGroups = [ "media" ];
    bazarr.extraGroups = [ "media" ];
  };

  systemd.tmpfiles.rules = [
    "d /media          0775 root  media -"
    "d /media/movies   0775 root  media -"
    "d /media/tv       0775 root  media -"
    "d /media/downloads 0775 root media -"
  ];

  systemd.services.radarr.serviceConfig = { Group = lib.mkForce "media"; UMask = "0002"; };
  systemd.services.sonarr.serviceConfig = { Group = lib.mkForce "media"; UMask = "0002"; };
  systemd.services.bazarr.serviceConfig = { Group = lib.mkForce "media"; UMask = "0002"; };
  systemd.services.qbittorrent.serviceConfig = { Group = lib.mkForce "media"; UMask = "0002"; };
  systemd.services.jellyfin.serviceConfig = { Group = lib.mkForce "media"; UMask = "0002"; };

  services = {
    bazarr = {
      enable = true;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    qbittorrent = {
      enable = true;
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          WebUI = {
            Enabled = true;
            Username = "admin";
            Password_PBKDF2 = "@ByteArray(Jo434KrgIzAgdJ/kRg/I0A==:wtF5EPUmEPd7vGLq3WzjHy66FUlZWg34KycyAKEsWsNxRlIq6UR2XKx2itYQ0FGOgrOKae0cZApsheTR5swLzQ==)";
          };
          General.Locale = "en";
          Downloads.SavePath = "/media/downloads";
        };
      };
    };

    radarr = {
      enable = true;
      openFirewall = true;
    };

    sonarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
