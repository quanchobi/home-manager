# Shared base for every user. Per-user entry points live in users/<name>/ and
# only carry what differs from this.
{
  config,
  lib,
  ...
}:
{
  imports = [
    #./accounts # disabled until I finish it
    ./cli
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage. `home.username` is set by each user.
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
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
