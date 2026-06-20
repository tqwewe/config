{ config, inputs, lib, pkgs, ... }:

let
  cudaLibPath = lib.makeLibraryPath [
    pkgs.cudaPackages.cuda_cudart
    pkgs.cudaPackages.libcublas
    pkgs.cudaPackages.cudnn
  ];

  # Patched hermes-agent source with Matrix voice detection fix
  patchedHermesSrc = pkgs.applyPatches {
    name = "hermes-agent-patched";
    src = inputs.hermes-agent;
    patches = [
      ../../patches/hermes-matrix-voice.patch
      ../../patches/hermes-npm-deps-hash.patch
    ];
  };

  # Build hermes-agent from the patched source,
  # passing through the hermes-agent flake's transitive inputs
  hermesInputs = inputs.hermes-agent.inputs;

  customHermesAgent = pkgs.callPackage "${patchedHermesSrc}/nix/hermes-agent.nix" {
    inherit (hermesInputs) uv2nix pyproject-nix pyproject-build-systems;
    npm-lockfile-fix =
      hermesInputs.npm-lockfile-fix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    rev = inputs.hermes-agent.rev or null;
  };
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
    agent-browser
    chromium
    protonmail-bridge
  ];

  age.secrets.hermesEnv = {
    file = ../../secrets/hermesEnv.age;
    owner = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    package = customHermesAgent;
    settings = {
      approvals.mode = "smart";
      model = {
        default = "deepseek-v4-flash";
        provider = "deepseek";
        base_url = "https://api.deepseek.com/v1";
      };
      stt.enabled = true;
      matrix = {
        auto_thread = false;
        session_scope = "room";
      };
    };
    extraDependencyGroups = [ "voice" "matrix" ];
    environment = {
      MATRIX_HOMESERVER = "https://matrix.org";
      MATRIX_USER_ID = "@tqwewe_bot:matrix.org";
      MATRIX_ALLOWED_USERS = "@tqwewe:matrix.org";
      MATRIX_REQUIRE_MENTION = "false";
      MATRIX_DEVICE_ID = "HERMES_AGENT_DESKTOP";
      MATRIX_HOME_ROOM = "!RnmhFdVSSyvdkOttoS:matrix.org";
    };
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
