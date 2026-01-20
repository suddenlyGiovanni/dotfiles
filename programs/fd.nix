# fd - A simple, fast and user-friendly alternative to find
# https://github.com/sharkdp/fd
# https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/fd.nix
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
#   - Hyperlink support for clickable file paths in terminals
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
#   fd -l                      Long listing format (like ls -l)
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
#   fd -l -t f                   List files with details (permissions, size)
#   fd -e nix -x nixfmt          Format all Nix files
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# fd is used throughout this configuration:
#
#   fzf:
#     - FZF_DEFAULT_COMMAND (default file listing)
#     - FZF_CTRL_T_COMMAND (⌃T file widget)
#     - FZF_ALT_C_COMMAND (⌥C directory widget)
#
#   Fish functions:
#     - fe: fuzzy edit (fd + fzf + bat + $EDITOR)
#     - fcd: fuzzy cd (fd + fzf + eza)
#
#   yazi:
#     - File searching within the file manager
#
# This provides .gitignore-aware, fast fuzzy finding throughout the shell.
#
# Related tools:
#   - ripgrep.nix: Content searching (grep replacement)
#   - fzf.nix: Fuzzy finding interface
#   - eza.nix: Modern ls replacement
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
    #
    # Note: These patterns are kept in sync with ripgrep.nix for consistency.
    # fd also respects .gitignore, .ignore, and .fdignore files.
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
      ".fseventsd"
      ".TemporaryItems"

      # ── Nix ─────────────────────────────────────────────────────────────
      "result" # nix build output symlink
      "result-*" # multiple outputs
      ".devenv/" # devenv state
      ".direnv/" # direnv cache

      # ── Build Artifacts & Dependencies ──────────────────────────────────
      "node_modules/"
      "target/" # Rust
      "dist/"
      "build/"
      ".build/" # Swift
      "out/"
      "vendor/" # Go modules (be careful, may want to search these)

      # ── JavaScript/TypeScript Framework Caches ──────────────────────────
      ".next/"
      ".nuxt/"
      ".output/" # Nuxt 3
      ".svelte-kit/"
      ".turbo/"
      ".parcel-cache/"
      ".vercel/"
      ".netlify/"

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
      ".tox/"

      # ── Java/JVM ────────────────────────────────────────────────────────
      ".gradle/"
      "*.class"

      # ── Infrastructure ──────────────────────────────────────────────────
      ".terraform/"
      ".terragrunt-cache/"

      # ── IDE & Editor ────────────────────────────────────────────────────
      ".idea/"
      ".vscode/" # Usually want to keep, but large in monorepos
      "*.swp"
      "*.swo"
      "*~"

      # ── Test Coverage ───────────────────────────────────────────────────
      "coverage/"
      ".coverage/"
      ".nyc_output/"
      "htmlcov/"

      # ── Caches ──────────────────────────────────────────────────────────
      ".cache/"
      "*.cache"
      ".sass-cache/"
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
      # Follow symbolic links (useful for monorepos with linked packages)
      "--follow"

      # Enable hyperlinks in output (clickable paths in Ghostty, iTerm2, etc.)
      # Uses file:// URLs that open in default application when clicked
      "--hyperlink=auto"
    ];
  };
}
