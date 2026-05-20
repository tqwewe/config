{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  hardware.xpadneo.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

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

      mkdir -p ~/.local/share/Steam
      echo "unShaderBackgroundProcessingThreads $STEAM_THREADS" > ~/.local/share/Steam/steam_dev.cfg
    '';
  };

  # If fps stutter, can try this
  # powerManagement.cpuFreqGovernor = "performance";
  # systemd.services.cpu-performance = {
  #   description = "Set CPU to performance mode";
  #   after = [ "multi-user.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "oneshot";
  #   script = ''
  #     echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  #     echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  #   '';
  # };

  environment.systemPackages = with pkgs; [
    protonup-ng
  ];
}
