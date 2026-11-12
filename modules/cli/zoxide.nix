{
  # `cd` becomes zoxide: plain paths behave as before, anything else jumps to
  # the best frecency match; `cdi` picks interactively. Also feeds `sesh list -z`.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };
}
