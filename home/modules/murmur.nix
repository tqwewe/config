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
    };
    Service = {
      ExecStart = lib.getExe murmur;
      Restart = "on-failure";
      RestartSec = 3;
      # user services don't inherit the login session's environment, which is where nixos sets this
      Environment = [ "YDOTOOL_SOCKET=/run/ydotoold/socket" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
