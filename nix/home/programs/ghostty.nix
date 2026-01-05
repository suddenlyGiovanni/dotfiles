# Ghostty terminal emulator configuration
# https://ghostty.org/docs/config
{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;

    # Shell integrations
    enableZshIntegration = true;
    enableFishIntegration = true;

    # Syntax highlighting for bat
    installBatSyntax = true;

    settings = {
      # Font configuration
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 14;
      theme = "dark:Catppuccin Frappe,light:Catppuccin Latte";

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
}
