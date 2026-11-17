# Identity, signing and `enable` are per user.
{
  programs.git.settings = {
    init.defaultBranch = "main";
    diff.tool = "nvimdiff";
    difftool.prompt = false;
    merge.tool = "nvimdiff";
    mergetool = {
      prompt = false;
      keepBackup = false;
    };
  };
}
