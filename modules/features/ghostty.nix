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
        # font-family is deliberately unset: Ghostty embeds JetBrains Mono plus a
        # symbols-only Nerd Font and sizes icons by Nerd Fonts' own rules (up to
        # two cells). The patched "Nerd Font Mono" family squeezes every icon
        # into one cell. Glyphs the embedded symbols font lacks (e.g. newer
        # cod-* icons) fall back to the installed nerd-fonts.jetbrains-mono.
        # Check which face renders a codepoint: `ghostty +show-face --cp=0xf418`
        # Ligatures (->, !=, =>) are JetBrains Mono's default; to turn them off:
        # font-feature = "-calt";
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
