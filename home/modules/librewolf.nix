{
  programs.librewolf = {
    enable = true;

    settings = {
      "identity.fxaccounts.enabled" = true;
      "media.autoplay.blocking_policy" = 0;
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.downloads" = false;
      "privacy.resistFingerprinting" = false;
      "webgl.disabled" = false;
    };
  };
}
