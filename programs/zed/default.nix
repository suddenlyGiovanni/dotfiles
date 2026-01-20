# Zed editor configuration
# Zed is installed via Homebrew (see modules/homebrew.nix)
# This module manages configuration file symlinks
#
# https://zed.dev/docs/configuring-zed
{
  config,
  userConfig,
  ...
}: {
  # ── Config File Symlinks ──────────────────────────────────────────────────
  # Zed actively modifies its config files, so we use mkOutOfStoreSymlink
  # to keep them editable in place
  xdg.configFile = {
    "zed/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/programs/zed/settings.json";
    };
    "zed/keymap.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/programs/zed/keymap.json";
    };
    "zed/tasks.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/programs/zed/tasks.json";
    };
  };
}
