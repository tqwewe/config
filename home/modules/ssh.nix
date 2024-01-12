{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      server = {
        hostname = "170.64.147.60";
        user = "ari";
        extraOptions = {
          serverAliveInterval = "20";
          TCPKeepAlive = "no";
        };
      };
    };
  };
}
