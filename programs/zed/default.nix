# Zed editor configuration
# Zed is installed via Homebrew (see darwin/modules/homebrew.nix)
# This module manages configuration file symlinks
#
# https://zed.dev/docs/configuring-zed
{
  config,
  userConfig,
  ...
}: let
  # Directory containing this module and its config files
  zedConfigDir = ./.;
in {
  # ── Config File Symlinks ──────────────────────────────────────────────────
  # Zed actively modifies its config files, so we use mkOutOfStoreSymlink
  # to keep them editable in place
  xdg.configFile = {
    "zed/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/nix/home/programs/zed/settings.json";
    };
    "zed/keymap.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/nix/home/programs/zed/keymap.json";
    };
    "zed/tasks.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/nix/home/programs/zed/tasks.json";
    };
  };
}
