# WireGuard tunnel to zion, which serves status, ntfy, atuin, mailadmin and the other
# private vhosts on 10.100.0.1 only. Each host's peer entry (public key and /32) lives
# in ~/dev/tqwewe/zion/modules/wireguard.nix; adding a host here without one there
# gives a tunnel that never handshakes.
#
# wg-quick rather than a NetworkManager profile so it is declarative and comes up at
# boot without a login. Only the tunnel subnet is routed; everything else, Tailscale
# included, is untouched.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.zionWireguard;
in
{
  options.services.zionWireguard = {
    enable = lib.mkEnableOption "the WireGuard tunnel to zion";

    address = lib.mkOption {
      type = lib.types.str;
      example = "10.100.0.2/24";
      description = "This host's tunnel address, matching its /32 in zion's peer list.";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "agenix-encrypted WireGuard private key for this host.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.zionWireguardKey.file = cfg.privateKeyFile;

    networking.wg-quick.interfaces.zion = {
      address = [ cfg.address ];
      privateKeyFile = config.age.secrets.zionWireguardKey.path;
      peers = [
        {
          publicKey = "xqNWovxU/aMbiuYxiNHU2BBNk1qracrPct3ndo/e4wE=";
          endpoint = "178.104.137.172:51820";
          allowedIPs = [ "10.100.0.0/24" ];
          persistentKeepalive = 25;
        }
      ];
    };

    # Dual-booting Windows leaves the RTC in local time, so the clock starts 11 hours
    # fast until timesyncd corrects it. A handshake sent in that window stores a
    # future timestamp on zion, which then silently drops every later handshake as a
    # replay until real time catches up. Waiting for the first sync avoids that; the
    # timeout and the leading "-" stop an offline boot from holding the tunnel forever.
    systemd.services.wg-quick-zion.serviceConfig.ExecStartPre =
      "-${pkgs.coreutils}/bin/timeout 90 ${config.systemd.package}/lib/systemd/systemd-time-wait-sync";
  };
}
