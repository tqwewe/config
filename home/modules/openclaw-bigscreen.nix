{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = with inputs; [
    nix-openclaw.overlays.default
  ];

  # SSH tunnel forwarding desktop's loopback gateway to bigscreen's loopback
  systemd.user.services."openclaw-tunnel" = {
    Unit = {
      Description = "SSH tunnel to desktop openclaw gateway";
      After = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.openssh}/bin/ssh -N -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -L 18789:127.0.0.1:18789 ari@100.118.150.103";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.user.services."openclaw-node" = {
    Unit = {
      Description = "OpenClaw node (bigscreen)";
      After = [ "openclaw-tunnel.service" ];
      Requires = [ "openclaw-tunnel.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.openclaw-gateway}/bin/openclaw node run --host 127.0.0.1 --port 18789 --display-name bigscreen";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
