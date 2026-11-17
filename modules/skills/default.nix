# Software-engineering agent skills for every user, linked into omp's user
# skill directory. Host- or user-specific skills stay with that user.
{
  config,
  pkgs,
  inputs,
  ...
}:
let
  # Drives agents in tmux panes from tmux-agent-indicator state (enabled in
  # ../cli/tmux.nix); the agent-indicator skill documents it.
  tmuxAgent = pkgs.writeShellApplication {
    name = "tmux-agent";
    runtimeInputs = [
      config.programs.tmux.package
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
    ];
    text = builtins.readFile ./agent-indicator/scripts/tmux-agent;
  };
in
{
  home.packages = [ tmuxAgent ];

  home.file = {
    ".omp/agent/skills/frontend-design".source = "${inputs.anthropic-skills}/skills/frontend-design";
    ".omp/agent/skills/lxd".source = "${inputs.openstack-agentic-skills}/lxd";
    # Pane control, and agents in panes via tmux-agent-indicator state.
    ".omp/agent/skills/tmux".source = ./tmux;
    ".omp/agent/skills/agent-indicator".source = ./agent-indicator;
  };
}
