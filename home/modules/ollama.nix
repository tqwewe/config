{
  services.ollama = {
    enable = true;
    acceleration = "cuda";

    environmentVariables = {
      # 4096 (the vram-based default) leaves no room once open-webui injects
      # its builtin tool schemas; q8 kv cache keeps 16k affordable on 11.6 GiB.
      OLLAMA_CONTEXT_LENGTH = "16384";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };
}
