{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cudaLibPath = lib.makeLibraryPath [
    pkgs.cudaPackages.cuda_cudart
    pkgs.cudaPackages.libcublas
    pkgs.cudaPackages.cudnn
  ];
in
{

  imports = with inputs; [
    hermes-agent.nixosModules.default
  ];

  users.users.hermes.extraGroups = [ "wheel" ];
  security.sudo.extraRules = [
    {
      users = [ "hermes" ];
      commands = [
        {
          command = "ALL";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    chromium
    protonmail-bridge
  ];

  age.secrets.hermesEnv = {
    file = ../../secrets/hermesEnv.age;
    owner = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    settings = {
      approvals.mode = "smart";
      model = {
        default = "deepseek-v4-flash";
        provider = "deepseek";
        base_url = "https://api.deepseek.com/v1";
      };
      stt.enabled = true;
    };
    extraDependencyGroups = [ "voice" ];
    environmentFiles = [ config.age.secrets.hermesEnv.path ];
    addToSystemPackages = true;
  };

  systemd.services.hermes-agent = {
    environment.LD_LIBRARY_PATH = "${cudaLibPath}:/run/opengl-driver/lib";
    serviceConfig = {
      TimeoutStopSec = 210;
      NoNewPrivileges = lib.mkForce false;
    };
  };
}
