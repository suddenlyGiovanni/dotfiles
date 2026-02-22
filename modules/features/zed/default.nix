# Zed editor configuration
# Zed is installed via Homebrew (see modules/features/homebrew.nix)
# This module manages configuration file symlinks
#
# https://zed.dev/docs/configuring-zed
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.zed = {config, ...}: {
    # ── Config File Symlinks ──────────────────────────────────────────────────
    # Zed actively modifies its config files, so we use mkOutOfStoreSymlink
    # to keep them editable in place
    xdg.configFile = {
      "zed/settings.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/zed/settings.json";
      };
      "zed/keymap.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/zed/keymap.json";
      };
      "zed/tasks.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/zed/tasks.json";
      };
    };
  };
}
