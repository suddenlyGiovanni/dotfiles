# Ghostty terminal emulator configuration
# https://ghostty.org/docs/config
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
_: {
  flake.modules.homeManager.ghostty = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) attrByPath;

    # Safe lookup for optional module enable flags with fallback to false
    programEnabled = path: attrByPath (["programs"] ++ path ++ ["enable"]) false config;
  in {
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty-bin;

      # Shell integrations - derived from enabled shells
      # Uses safe lookup with fallback for modules that may not be imported
      enableZshIntegration = programEnabled ["zsh"];
      enableFishIntegration = programEnabled ["fish"];
      enableBashIntegration = programEnabled ["bash"];

      # Syntax highlighting for bat - derived from bat being enabled
      installBatSyntax = programEnabled ["bat"];

      settings = {
        # Font configuration
        font-family = "JetBrainsMono Nerd Font Mono";
        font-size = 14;
        theme = "dark:GitHub Dark High Contrast,light:GitHub Light High Contrast";

        # Window appearance
        window-decoration = "auto";
        window-padding-x = 8;
        window-padding-y = 8;

        # macOS specific
        macos-titlebar-style = "transparent";
        macos-option-as-alt = true;

        # Cursor
        # cursor-style = "block";
        # cursor-style-blink = false;

        # Scrollback
        # scrollback-limit = 10000;

        # Copy behavior
        copy-on-select = "clipboard";
      };
    };
  };
}
