{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "hosts" ];
    matchBlocks."*" = {
      # Reuse one connection per host for 10 minutes after the last session.
      controlMaster = "auto";
      controlPath = "~/.ssh/control-%C";
      controlPersist = "10m";
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
    };
  };
}
