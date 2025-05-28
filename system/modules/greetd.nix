{ pkgs, ... }:
let
  hyprland = "${pkgs.hyprland}/bin/Hyprland";
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  args = [
    "--time"
    "--remember"
    "--remember-session"
    "--theme border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red"
    "--sessions ${hyprland}"
  ];
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = builtins.concatStringsSep " " ([ tuigreet ] ++ args);
        user = "greeter";
      };
    };
  };

  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
