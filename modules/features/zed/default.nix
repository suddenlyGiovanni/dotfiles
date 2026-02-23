# Zed editor configuration
# Cross-cutting feature: darwin cask installation + home-manager config symlinks
#
# https://zed.dev/docs/configuring-zed
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  # ── Darwin: install Zed via Homebrew ───────────────────────────────────────
  flake.modules.darwin.zed = _: {
    homebrew.casks = ["zed@preview"];
  };

  # ── Home Manager: configuration file symlinks ─────────────────────────────
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
