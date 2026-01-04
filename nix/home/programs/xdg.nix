# XDG configuration and non-nix managed config symlinks
#
# This module:
# 1. Enables XDG base directory specification
# 2. Symlinks config files from the dotfiles repo's config/ directory
#
# For apps that don't have home-manager modules or where we prefer
# their native config format (zed, ghostty, etc.)
{
  config,
  userConfig,
  ...
}: {
  xdg = {
    enable = true;

    # Symlink non-nix managed configs from dotfiles/config/
    configFile = {
      # Zed editor configuration
      "zed/settings.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/zed/settings.json";
      };
      "zed/keymap.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/zed/keymap.json";
      };
      "zed/tasks.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/zed/tasks.json";
      };

      # Git commit message template
      "git/.gitmessage" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/git/.gitmessage";
      };
    };
  };
}
