{ inputs, pkgs, ... }:
let
  openclawNodeExec = pkgs.writeShellScript "openclaw-node-exec" ''
    set -euo pipefail
    exec ${pkgs.openclaw-gateway}/bin/openclaw node run \
      --host desktop.tailad8772.ts.net \
      --port 443 \
      --tls \
      --display-name bigscreen
  '';
in
{
  nixpkgs.overlays = with inputs; [
    nix-openclaw.overlays.default
  ];

  systemd.user.services."openclaw-node" = {
    Unit.Description = "OpenClaw node (bigscreen)";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${openclawNodeExec}";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
