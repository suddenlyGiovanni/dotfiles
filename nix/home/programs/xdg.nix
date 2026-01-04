# XDG Base Directory configuration and non-nix managed config symlinks
#
# This module:
# 1. Explicitly sets XDG base directories
# 2. Symlinks config files from the dotfiles repo's config/ directory
#
# Reference: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
{
  config,
  userConfig,
  ...
}: {
  xdg = {
    enable = true;

    # Explicitly set XDG directories (these are the defaults, but being explicit is good)
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";

    # Note: xdg.userDirs is Linux-only, macOS has its own ~/Desktop, ~/Documents, etc.

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

      # Readline config for consistent line editing
      "readline/inputrc".text = ''
        # Be 8 bit clean
        set input-meta on
        set output-meta on

        # Color files by types
        set colored-stats on
        # Append char to indicate type
        set visible-stats on
        # Mark symlinked directories
        set mark-symlinked-directories on
        # Color the common prefix
        set colored-completion-prefix on
        # Color the common prefix in menu-complete
        set menu-complete-display-prefix on

        # Case insensitive completion
        set completion-ignore-case on
        # Treat hyphens and underscores as equivalent
        set completion-map-case on

        # Show all completions at once
        set show-all-if-ambiguous on
        set show-all-if-unmodified on
      '';
    };
  };
}
