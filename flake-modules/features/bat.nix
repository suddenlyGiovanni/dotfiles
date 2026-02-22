# bat - A cat clone with syntax highlighting and Git integration
# https://github.com/sharkdp/bat
# https://github.com/nix-community/home-manager/blob/master/modules/programs/bat.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# bat is a cat(1) clone with syntax highlighting for a large number of
# programming and markup languages. It also integrates with Git to show
# modifications and supports automatic paging.
#
# Key features:
#   - Syntax highlighting for 100+ languages
#   - Git integration (shows modifications in the gutter)
#   - Automatic paging (uses less by default)
#   - File concatenation (non-interactive mode)
#   - Custom themes support
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   bat <file>                 Display file with syntax highlighting
#   bat <file1> <file2>        Concatenate and display multiple files
#   bat -n <file>              Show line numbers only (no other decorations)
#   bat -p <file>              Plain mode (no decorations, just highlighting)
#   bat -A <file>              Show non-printable characters
#   bat -l <lang> <file>       Force specific language for highlighting
#   bat --list-languages       List supported languages
#   bat --list-themes          List available themes
#   bat -d <file>              Only show git diff decorations
#
# ══════════════════════════════════════════════════════════════════════════════
# STYLE COMPONENTS
# ══════════════════════════════════════════════════════════════════════════════
#
# The --style option controls what decorations are shown:
#
#   full      Show all components (default)
#   auto      Same as full, unless piping
#   plain     No decorations (just syntax highlighting)
#   numbers   Line numbers only
#   changes   Git changes only
#   header    Filename header only
#   grid      Grid lines only
#
# Combine with comma: --style=numbers,changes
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# bat is used throughout this configuration:
#   - fzf ⌃T preview: file content with syntax highlighting
#   - fzf ⌃R preview: command history
#   - help function: --help output with highlighting (--language=help)
#   - man pages: MANPAGER set to use bat for colorized man pages
#   - git diffs: via batdiff wrapper (bat-extras)
#
# ══════════════════════════════════════════════════════════════════════════════
# EXTRAS (bat-extras)
# ══════════════════════════════════════════════════════════════════════════════
#
#   batman    View man pages with bat (also aliased to 'man' in some setups)
#   batdiff   Diff files using bat for syntax highlighting
#   batgrep   Search with ripgrep, display with bat
#   batwatch  Watch files with bat (like watch + cat)
#   prettybat Format and highlight code
#
_: {
  flake.modules.homeManager.bat = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    programs.bat = {
      enable = true;
      package = mkDefault pkgs.bat;

      # ────────────────────────────────────────────────────────────────────────
      # Configuration
      # ────────────────────────────────────────────────────────────────────────
      # Written to ~/.config/bat/config
      config = {
        # Theme configuration with automatic dark/light mode detection
        # On macOS, bat detects system appearance and switches themes automatically
        # Use `bat --list-themes` to see available themes
        # Use `bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"`
        # to preview themes interactively
        theme = mkDefault "auto:system";

        # Theme used when system is in dark mode
        # "ansi" adapts to terminal colors; alternatives: "TwoDark", "Dracula", "OneHalfDark"
        theme-dark = mkDefault "ansi";

        # Theme used when system is in light mode
        # "ansi" adapts to terminal colors; alternatives: "GitHub", "OneHalfLight"
        theme-light = mkDefault "ansi";

        # Default style: show line numbers and git changes
        # Use 'full' for all decorations, 'plain' for none
        style = "numbers,changes,header,grid";

        # Enable italic text (if terminal supports it)
        italic-text = "always";

        # Pager configuration
        # -R: interpret ANSI color sequences
        # -F: quit if output fits on one screen
        # -X: don't clear screen on exit
        pager = "less -RFX";

        # Map additional file types to languages
        # Useful for files without extensions or non-standard extensions
        map-syntax = [
          # Nix files
          "flake.lock:JSON"
          # Config files
          ".envrc:Bash"
          ".env:Bash"
          ".env.*:Bash"
          "*.conf:INI"
          # Ignore files
          ".gitignore:Git Ignore"
          ".ignore:Git Ignore"
          ".fdignore:Git Ignore"
          # CI/CD
          "Jenkinsfile:Groovy"
          "*.jenkinsfile:Groovy"
          # Docker
          "Dockerfile.*:Dockerfile"
          "*.dockerfile:Dockerfile"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extra Packages (bat-extras)
      # ────────────────────────────────────────────────────────────────────────
      # Useful wrappers that leverage bat's capabilities
      extraPackages = with pkgs.bat-extras; [
        batman # View man pages with bat syntax highlighting
        batdiff # Diff with syntax highlighting
        batgrep # Ripgrep + bat (search with pretty output)
        batwatch # Watch files with syntax highlighting
        prettybat # Format and highlight code (formatter + bat)
      ];

      # ────────────────────────────────────────────────────────────────────────
      # Custom Themes
      # ────────────────────────────────────────────────────────────────────────
      # Additional themes installed to ~/.config/bat/themes/
      # After adding themes, bat cache is automatically rebuilt
      # Uncomment to add custom themes:
      #
      # themes = {
      #   catppuccin-mocha = {
      #     src = pkgs.fetchFromGitHub {
      #       owner = "catppuccin";
      #       repo = "bat";
      #       rev = "d714cc1d358ea51bfc02550dabab693f70cccea0";
      #       hash = "sha256-Q5B4NDrfCIK3UAMs94vdXnR42k4AXCqZz6sRn8bzmf4=";
      #     };
      #     file = "themes/Catppuccin Mocha.tmTheme";
      #   };
      # };
      themes = {};

      # ────────────────────────────────────────────────────────────────────────
      # Custom Syntaxes
      # ────────────────────────────────────────────────────────────────────────
      # Additional syntax definitions installed to ~/.config/bat/syntaxes/
      # Useful for languages not included in bat's default set
      syntaxes = {};
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Man Pages
    # ──────────────────────────────────────────────────────────────────────────
    # MANPAGER falls back to the default (less -R) from session.nix.
    # For syntax-highlighted man pages, use `batman <command>` directly.
  };
}
