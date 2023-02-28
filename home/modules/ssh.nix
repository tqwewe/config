{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      server = {
        hostname = "139.180.178.235";
        user = "ari";
        extraOptions = {
          serverAliveInterval = "20";
          TCPKeepAlive = "no";
        };
      };
    };
  };
}
