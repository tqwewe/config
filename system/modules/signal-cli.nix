{ pkgs, ... }:
let
  account = "+61493074349";
  httpHost = "127.0.0.1";
  httpPort = 9090;
  stateDir = "/var/lib/signal-cli";
in
{
  users.users.signal-cli = {
    isSystemUser = true;
    group = "signal-cli";
    home = stateDir;
    createHome = false;
  };
  users.groups.signal-cli = { };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 signal-cli signal-cli -"
  ];

  environment.systemPackages = [ pkgs.signal-cli ];

  systemd.services.signal-cli = {
    description = "signal-cli daemon (HTTP mode)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      User = "signal-cli";
      Group = "signal-cli";
      ExecStart = "${pkgs.signal-cli}/bin/signal-cli --config ${stateDir} --account ${account} daemon --http ${httpHost}:${toString httpPort}";
      Restart = "on-failure";
      RestartSec = 5;
      StateDirectory = "signal-cli";
      StateDirectoryMode = "0700";
    };
  };
}
