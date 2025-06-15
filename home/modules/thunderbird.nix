{ inputs, ... }:
{
  programs.thunderbird = {
    enable = true;
    package = inputs.unstable.legacyPackages.x86_64-linux.thunderbird;

    profiles = {
      ari = {
        isDefault = true;
      };
    };
  };
}
