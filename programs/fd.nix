# fd - A simple, fast and user-friendly alternative to find
# https://github.com/sharkdp/fd
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fd.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# fd is a program to find entries in your filesystem. It is a simple, fast and
# user-friendly alternative to find. While it does not aim to support all of
# find's powerful functionality, it provides sensible (opinionated) defaults
# for a majority of use cases.
#
# Key features:
#   - Intuitive syntax: `fd PATTERN` instead of `find -iname '*PATTERN*'`
#   - Regular expressions (default) and glob-based patterns
#   - Smart case: search case-insensitively unless pattern has uppercase
#   - Ignores hidden files/directories and .gitignore patterns by default
#   - Colorized output and parallel command execution
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   fd                         List all files recursively
#   fd <pattern>               Find entries matching pattern (regex)
#   fd -g <pattern>            Find entries matching pattern (glob)
#   fd <pattern> <path>        Search in specific directory
#   fd -e <ext>                Filter by file extension
#   fd -e <ext> -e <ext2>      Filter by multiple extensions
#   fd -t f                    Only files
#   fd -t d                    Only directories
#   fd -t l                    Only symlinks
#   fd -t x                    Only executables
#   fd -H                      Include hidden files
#   fd -I                      Include ignored files (.gitignore)
#   fd -u                      Unrestricted: include hidden + ignored
#   fd -x <cmd>                Execute command for each result
#   fd -X <cmd>                Execute command with all results as args
#
# ══════════════════════════════════════════════════════════════════════════════
# EXAMPLES
# ══════════════════════════════════════════════════════════════════════════════
#
#   fd '\.rs$'                   All Rust files
#   fd -e md                     All Markdown files
#   fd -e jpg -e png             All JPEG and PNG files
#   fd test                      Files/dirs containing "test"
#   fd '^test'                   Files/dirs starting with "test"
#   fd -t d node_modules         All node_modules directories
#   fd -H '.env'                 Find .env files (hidden)
#   fd -x rm                     Delete all matches (careful!)
#   fd -e js -x prettier -w      Format all JS files with prettier
#   fd -t f -X vim               Open all files in vim
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# fd is used by fzf in this configuration for:
#   - FZF_DEFAULT_COMMAND (default file listing)
#   - FZF_CTRL_T_COMMAND (⌃T file widget)
#   - FZF_ALT_C_COMMAND (⌥C directory widget)
#
# This provides .gitignore-aware, fast fuzzy finding throughout the shell.
#
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.fd = {
    enable = true;
    package = mkDefault pkgs.fd;

    # ────────────────────────────────────────────────────────────────────────
    # Global Ignore Patterns
    # ────────────────────────────────────────────────────────────────────────
    # These patterns are always ignored, in addition to .gitignore rules.
    # Written to ~/.config/fd/ignore
    ignores = [
      # ── Version Control ─────────────────────────────────────────────────
      ".git/"
      ".hg/"
      ".svn/"

      # ── macOS ───────────────────────────────────────────────────────────
      ".DS_Store"
      "._*"
      ".Spotlight-V100"
      ".Trashes"

      # ── Build Artifacts & Dependencies ──────────────────────────────────
      "node_modules/"
      ".direnv/"
      "target/" # Rust
      "dist/"
      "build/"
      ".build/" # Swift
      "out/"

      # ── JavaScript/TypeScript Framework Caches ──────────────────────────
      ".next/"
      ".nuxt/"
      ".output/" # Nuxt 3
      ".svelte-kit/"
      ".turbo/"
      ".parcel-cache/"

      # ── Python ──────────────────────────────────────────────────────────
      "__pycache__/"
      ".pytest_cache/"
      ".mypy_cache/"
      ".ruff_cache/"
      "*.pyc"
      ".venv/"
      "venv/"
      ".eggs/"
      "*.egg-info/"

      # ── IDE & Editor ────────────────────────────────────────────────────
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"

      # ── Caches ──────────────────────────────────────────────────────────
      ".cache/"
      "*.cache"
    ];

    # ────────────────────────────────────────────────────────────────────────
    # Default Behavior
    # ────────────────────────────────────────────────────────────────────────
    # Whether to search hidden files by default.
    # When false (default), hidden files are excluded unless -H is passed.
    # We keep this false as fzf commands explicitly pass --hidden when needed.
    hidden = mkDefault false;

    # ────────────────────────────────────────────────────────────────────────
    # Extra Options
    # ────────────────────────────────────────────────────────────────────────
    # These are passed to fd by default via shell alias.
    extraOptions = [
      # Follow symbolic links
      "--follow"
    ];
  };
}
