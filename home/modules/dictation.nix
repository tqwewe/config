{ pkgs, ... }:
let
  whisper = pkgs.whisper-cpp.override { cudaSupport = true; };

  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
    hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
  };

  port = "8178";

  dictate = pkgs.writers.writePython3Bin "dictate" {
    libraries = [ pkgs.python3Packages.evdev ];
    flakeIgnore = [
      "E501"
      "E722"
    ];
  } (builtins.readFile ./dictation.py);
in
{
  home.packages = [ dictate ];

  systemd.user.services = {
    whisper-server = {
      Unit.Description = "whisper.cpp server for dictation";
      Service = {
        ExecStart = "${whisper}/bin/whisper-server --model ${model} --host 127.0.0.1 --port ${port} --language auto --no-timestamps";
        Restart = "on-failure";
        # cuda needs the driver libs from the nixos opengl dir
        Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
      };
      Install.WantedBy = [ "default.target" ];
    };

    dictate = {
      Unit = {
        Description = "Hold-to-talk dictation";
        After = [ "whisper-server.service" ];
        Wants = [ "whisper-server.service" ];
      };
      Service = {
        ExecStart = "${dictate}/bin/dictate";
        Restart = "on-failure";
        Environment = [
          "DICTATE_URL=http://127.0.0.1:${port}/inference"
          "DICTATE_KEY=KEY_VOICECOMMAND"
          "YDOTOOL_SOCKET=/run/ydotoold/socket"
          "PATH=${
            pkgs.lib.makeBinPath [
              pkgs.pipewire
              pkgs.ydotool
              pkgs.curl
            ]
          }"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
