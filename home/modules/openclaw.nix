{ config, inputs, lib, pkgs, ... }:
let
  openclawDocuments = ./openclaw-documents;
  workspaceDir = "${config.home.homeDirectory}/.openclaw/workspace";
  managedWorkspaceDocs = [
    "AGENTS.md"
    "SOUL.md"
    "TOOLS.md"
    "IDENTITY.md"
    "USER.md"
  ];
  defaultOpenclawInstance = config.programs.openclaw.instances.default;
  openclawGatewayExec = pkgs.writeShellScript "openclaw-gateway-exec" ''
    set -euo pipefail
    export OPENCLAW_GATEWAY_PASSWORD="$(${lib.getExe' pkgs.coreutils "cat"} ${config.age.secrets.openclawGatewayPassword.path})"
    export DEEPSEEK_API_KEY="$(${lib.getExe' pkgs.coreutils "cat"} ${config.age.secrets.deepseekApiKey.path})"
    exec ${defaultOpenclawInstance.package}/bin/openclaw gateway --port ${toString defaultOpenclawInstance.gatewayPort}
  '';
in
{
  imports = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  nixpkgs = {
    overlays = with inputs; [
      nix-openclaw.overlays.default
    ];
  };

  home.packages = with pkgs; [ whisper-cpp ];

  home.activation.openclawMigrateWorkspaceDocs = lib.hm.dag.entryBefore [ "openclawDocumentGuard" ] ''
    for name in ${lib.escapeShellArgs managedWorkspaceDocs}; do
      file="${workspaceDir}/$name"
      if [ -e "$file" ] && [ ! -L "$file" ]; then
        mv "$file" "$file.pre-nix-managed.$(date +%s)"
      fi
    done
  '';

  programs.openclaw = {
    documents = openclawDocuments;

    bundledPlugins = {
      summarize.enable = true;
      peekaboo.enable = false;
      sag.enable = true;
    };

    instances.default = {
      enable = true;
      plugins = [
        # Example plugin without config:
        # { source = "github:acme/hello-world"; }
      ];
      config = {
        gateway = {
          mode = "local";
          bind = "loopback";
          auth = {
            mode = "password";
          };
        };

        channels.telegram = {
          tokenFile = config.age.secrets.openclawTelegramBotToken.path;
          allowFrom = [ 8305464232 ];
          groups."*".requireMention = true;
        };

        tools.media.audio = {
          enabled = true;
          models = [{
            command = "/home/ari/.openclaw/bin/whisper-transcribe";
            type = "cli";
            args = [ "{{MediaPath}}" ];
            timeoutSeconds = 60;
          }];
        };

        env.vars.PATH = "/home/ari/.openclaw/bin:/home/ari/.local/bin:$PATH";

        models = {
          providers = {
            ollama = {
              api = "ollama";
              baseUrl = "http://localhost:11434";
              models = [
                {
                  id = "llama3.1:8b";
                  name = "llama3.1:8b";
                }
              ];
            };
            deepseek = {
              api = "openai-completions";
              baseUrl = "https://api.deepseek.com";
              models = [
                {
                  id = "deepseek-v4-flash";
                  name = "DeepSeek V4 Flash";
                }
                {
                  id = "deepseek-v4-pro";
                  name = "DeepSeek V4 Pro";
                }
              ];
            };
          };
        };

        agents.defaults = {
          model = {
            primary = "deepseek/deepseek-v4-flash";
            fallbacks = [ "deepseek/deepseek-v4-pro" ];
          };

          heartbeat.model = "ollama/llama3.1:8b";

          compaction.memoryFlush = {
            enabled = true;
            softThresholdTokens = 4000;
          };
        };

        plugins.entries."device-pair" = {
          enabled = true;
          config.publicUrl = "https://desktop.tailad8772.ts.net";
        };
      };
    };
  };

  systemd.user.services."openclaw-gateway" = {
    Install.WantedBy = [ "default.target" ];
    Service.ExecStart = lib.mkForce "${openclawGatewayExec}";
  };

}
