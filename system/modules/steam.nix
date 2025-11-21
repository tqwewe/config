{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.xpadneo.enable = true;

  # Systemd user service that auto-configures Steam shader threads
  systemd.user.services.steam-shader-config = {
    description = "Configure Steam shader preprocessing threads";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      THREADS=$(${pkgs.coreutils}/bin/nproc)
      STEAM_THREADS=$((THREADS - 4))

      # Ensure minimum of 4 threads
      if [ $STEAM_THREADS -lt 4 ]; then
        STEAM_THREADS=4
      fi

      mkdir -p ~/.steam/steam
      echo "unShaderBackgroundProcessingThreads $STEAM_THREADS" > ~/.steam/steam/steam_dev.cfg
    '';
  };

  environment.systemPackages = with pkgs; [
    protonup-ng
  ];
}
