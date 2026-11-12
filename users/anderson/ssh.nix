{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "hosts" ];
    settings."*" = {
      # Reuse one connection per host for 10 minutes after the last session.
      ControlMaster = "auto";
      ControlPath = "~/.ssh/control-%C";
      ControlPersist = "10m";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
  };
}
