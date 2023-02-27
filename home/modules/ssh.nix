{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      server = {
        hostname = "139.180.178.235";
        user = "ari";
      };
    };
  };
}
