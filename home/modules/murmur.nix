{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  murmur = pkgs.callPackage "${inputs.murmur}/package.nix" { model = "large-v3-turbo-q8_0"; };
in
{
  home.packages = [ murmur ];

  systemd.user.services.murmur = {
    Unit = {
      Description = "Murmur hold-to-talk dictation";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      # keep retrying while outputs are gone (e.g. monitors off), instead of hitting the start limit
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = lib.getExe murmur;
      # the compositor closes the overlay when its output disappears, and iced then exits cleanly
      Restart = "always";
      RestartSec = 3;
      # user services don't inherit the login session's environment, which is where nixos sets this
      Environment = [
        "YDOTOOL_SOCKET=/run/ydotoold/socket"
        # primary monitor; otherwise kwin picks whichever output is active at startup
        "MURMUR_OUTPUT=DP-1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
