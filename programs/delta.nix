# delta - A syntax-highlighting pager for git, diff, and grep output
# https://github.com/dandavison/delta
# https://github.com/nix-community/home-manager/blob/master/modules/programs/delta.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# delta is a viewer for git and diff output that provides:
#   - Syntax highlighting using bat's engine
#   - Side-by-side diff view
#   - Line numbering
#   - Word-level diff highlighting
#   - Navigate mode (n/N to jump between files)
#   - Hyperlinks to file paths (clickable in supported terminals)
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
# delta is automatically used as git's pager when enableGitIntegration is true.
# All git commands that produce diff output will use delta:
#
#   git diff                   View working tree changes
#   git show                   View commit details
#   git log -p                 View commit history with patches
#   git blame                  View file annotations (with color)
#   git stash show -p          View stash contents
#
# Navigation in delta (when using less as pager):
#   n / N                      Jump to next/previous file (navigate mode)
#   j / k                      Scroll down/up
#   g / G                      Go to start/end
#   / or ?                     Search forward/backward
#   q                          Quit
#
# ══════════════════════════════════════════════════════════════════════════════
# FEATURES
# ══════════════════════════════════════════════════════════════════════════════
#
# Side-by-side view:
#   Use `git diff --side-by-side` or set side-by-side = true in options
#   Toggle with environment variable: DELTA_FEATURES="+side-by-side"
#
# Line numbers:
#   Enabled by default with line-numbers = true
#
# Navigate mode:
#   Press 'n' to jump to next file, 'N' for previous
#   Requires navigate = true (enabled below)
#
# Hyperlinks:
#   File paths are clickable in supported terminals (iTerm2, Ghostty, etc.)
#   Requires hyperlinks = true (enabled below)
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# delta integrates with:
#   - bat: Uses bat's syntax themes and highlighting engine
#   - git: Configured as core.pager and interactive.diffFilter
#   - lazygit: Can be configured to use delta for diffs
#
# Note: delta replaces batdiff for git diffs. batdiff is still useful for
# comparing arbitrary files outside of git.
#
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.delta = {
    enable = true;
    package = mkDefault pkgs.delta;

    # Enable git integration (sets core.pager and interactive.diffFilter)
    enableGitIntegration = true;

    # ────────────────────────────────────────────────────────────────────────
    # Options
    # ────────────────────────────────────────────────────────────────────────
    # See: https://dandavison.github.io/delta/configuration.html
    # Run `delta --help` for all available options
    options = {
      # ── Appearance ──────────────────────────────────────────────────────

      # Enable 24-bit truecolor (supported by Ghostty, iTerm2, etc.)
      # See: https://github.com/termstandard/colors
      true-color = "always";

      # Use terminal colors (adapts to dark/light mode like bat)
      # Alternatives: "Dracula", "OneHalfDark", "GitHub", etc.
      # Run `delta --list-syntax-themes` to see available themes
      dark = true;
      syntax-theme = mkDefault "ansi";

      # Show line numbers in the left margin
      line-numbers = true;

      # Enable side-by-side diff view by default
      # Toggle off with: DELTA_FEATURES=+ git diff
      # Or use: git diff --no-side-by-side (if supported)
      side-by-side = true;

      # ── Navigation ──────────────────────────────────────────────────────

      # Enable navigation mode: use n/N to jump between diff sections
      navigate = true;

      # ── Hyperlinks ──────────────────────────────────────────────────────

      # Make file paths clickable (opens in editor)
      # Works in iTerm2, Ghostty, and other terminals with hyperlink support
      hyperlinks = true;

      # ── Diff appearance ─────────────────────────────────────────────────

      # Show a marker for unchanged lines in the diff
      keep-plus-minus-markers = true;

      # Style for the file header
      file-style = "bold yellow ul";
      file-decoration-style = "none";

      # Style for the hunk header (e.g., @@ -1,3 +1,4 @@)
      hunk-header-style = "file line-number syntax";
      hunk-header-decoration-style = "blue box";

      # Line number styles
      line-numbers-left-style = "cyan";
      line-numbers-right-style = "cyan";
      line-numbers-minus-style = "red";
      line-numbers-plus-style = "green";

      # ── Merge conflicts ─────────────────────────────────────────────────

      # Style merge conflict markers
      merge-conflict-begin-symbol = "▼";
      merge-conflict-end-symbol = "▲";
      merge-conflict-ours-diff-header-style = "bold yellow";
      merge-conflict-theirs-diff-header-style = "bold yellow";
    };
  };
}
