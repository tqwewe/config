{
  services.pulseaudio = {
    enable = false;
    extraConfig = ''
      resample-method = speex-float-10
    '';
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
