{
  inputs,
  ...
}:
{
  imports = [
    inputs.stylix.homeModules.stylix
    ./options.nix
    #./accounts # disabled until I finish it
    ./cli
    ./gui
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "anderson";
    homeDirectory = "/home/anderson";
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # DO NOT CHANGE
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
