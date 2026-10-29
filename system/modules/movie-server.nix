{ config, lib, pkgs, ... }:
{
  users.groups.media = { };

  users.users = {
    ari.extraGroups = [ "media" ];
    radarr.extraGroups = [ "media" ];
    sonarr.extraGroups = [ "media" ];
    jellyfin.extraGroups = [ "media" ];
    qbittorrent.extraGroups = [ "media" ];
    bazarr.extraGroups = [ "media" ];
    xteve = {
      isSystemUser = true;
      group = "xteve";
      extraGroups = [ "media" ];
    };
  };

  users.groups.xteve = { };

  systemd.tmpfiles.rules = [
    "d /mnt/storage              0775 root  media -"
    "d /mnt/storage/movies       0775 root  media -"
    "d /mnt/storage/tvshows      0775 root  media -"
    "d /mnt/storage/downloads    0775 root  media -"
    "d /var/lib/xteve            0775 xteve xteve -"
    "d /var/lib/maintainerr      0750 1000  1000  -"
  ];

  systemd.services.radarr.serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };
  systemd.services.sonarr.serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };
  systemd.services.bazarr.serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };
  systemd.services.qbittorrent = {
    serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };
    # Remove stale lockfile on start — ProtectProc=invisible prevents qBittorrent from
    # checking if the previous PID is alive, causing it to exit immediately thinking
    # another instance is running.
    preStart = lib.mkBefore "rm -f /var/lib/qBittorrent/qBittorrent/config/lockfile";
  };
  systemd.services.jellyfin.serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };
  systemd.services.seerr.serviceConfig = { Group = lib.mkForce "media"; UMask = lib.mkForce "0002"; };

  systemd.services.xteve = {
    description = "xTeVe - IPTV proxy for Jellyfin";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xteve}/bin/xteve -port 34400 -config /var/lib/xteve";
      User = "xteve";
      Group = "xteve";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [ 34400 6246 ];

  # Maintainerr has no nixpkgs package/module, so run the upstream image.
  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.maintainerr = {
      image = "ghcr.io/maintainerr/maintainerr:3.30.0";
      # Host network so it can reach Jellyfin/Radarr/Sonarr/Seerr on 127.0.0.1.
      extraOptions = [ "--network=host" ];
      environment.TZ = config.time.timeZone;
      volumes = [ "/var/lib/maintainerr:/opt/data" ];
    };
  };

  services = {
    bazarr = {
      enable = true;
      openFirewall = true;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    flaresolverr = {
      enable = true;
    };

    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    qbittorrent = {
      enable = true;
      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent.Session = {
          DefaultSavePath = "/mnt/storage/downloads";
          MaxActiveDownloads = 5;
          MaxActiveTorrents = 20;
          MaxActiveUploads = 10;
          QueueingSystemEnabled = true;
          GlobalMaxRatio = 1.5;
          MaxRatioEnabled = true;
          MaxRatio = 1.5;
          MaxRatioAction = 0;
        };
        Preferences = {
          WebUI = {
            Enabled = true;
            Username = "admin";
            Password_PBKDF2 = "@ByteArray(Jo434KrgIzAgdJ/kRg/I0A==:wtF5EPUmEPd7vGLq3WzjHy66FUlZWg34KycyAKEsWsNxRlIq6UR2XKx2itYQ0FGOgrOKae0cZApsheTR5swLzQ==)";
          };
          General.Locale = "en";
          Downloads.SavePath = "/mnt/storage/downloads";
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

    seerr = {
      enable = true;
      openFirewall = true;
    };
  };
}
