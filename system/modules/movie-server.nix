{
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
        };
      };
    };

    radarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
