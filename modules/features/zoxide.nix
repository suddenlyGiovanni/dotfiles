# zoxide - A smarter cd command that learns your habits
# https://github.com/ajeetdsouza/zoxide
# https://github.com/nix-community/home-manager/blob/master/modules/programs/zoxide.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# Zoxide tracks your most-used directories and enables fast navigation using
# "frecency" (frequency + recency) scoring. With --cmd cd, it replaces the
# standard cd command while remaining fully backward-compatible.
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE (with --cmd cd)
# ══════════════════════════════════════════════════════════════════════════════
#
#   cd <path>        Navigate to path (works exactly like regular cd)
#   cd foo           Jump to highest-ranked directory matching "foo"
#   cd foo bar       Jump to directory matching "foo" then "bar" in path
#   cd foo /         Jump into a subdirectory starting with "foo"
#   cd ~/foo         Works like regular cd with absolute/relative paths
#   cd ..            Go one level up
#   cd -             Return to previous directory
#   cdi              Interactive selection with fzf (fuzzy finder)
#   cdi <keyword>    Interactive selection filtered by keyword
#   cd foo<TAB>      Show interactive completions (fish/zsh/bash 4.4+)
#
# ══════════════════════════════════════════════════════════════════════════════
# MATCHING ALGORITHM
# ══════════════════════════════════════════════════════════════════════════════
#
# 1. Case insensitive - "nvim" matches "NeoVim", "NVIM", etc.
# 2. Keywords must appear in order - "nvim custom" ≠ "custom nvim"
# 3. Last keyword must match last path component
#    - "dreams recorder" matches ".../dreams/recorder" ✓
#    - "dreams tools" won't match ".../dreams/recorder" ✗
# 4. Conflicts resolved by highest frecency score
#
# ══════════════════════════════════════════════════════════════════════════════
# FRECENCY SCORING
# ══════════════════════════════════════════════════════════════════════════════
#
# Each directory starts with score 1, incremented by 1 on each visit.
# Recency multipliers are applied when querying:
#
#   Last access time      │ Multiplier
#   ──────────────────────┼───────────
#   Within the last hour  │ score × 4
#   Within the last day   │ score × 2
#   Within the last week  │ score ÷ 2
#   Older                 │ score ÷ 4
#
# Database auto-prunes when total score exceeds _ZO_MAXAGE (default: 10000).
# Scores are rebalanced to ~90% of maxage, entries below 1 are removed.
# Theoretical max entries: 4 × _ZO_MAXAGE (lower in practice).
#
# ══════════════════════════════════════════════════════════════════════════════
# MANAGEMENT COMMANDS
# ══════════════════════════════════════════════════════════════════════════════
#
#   zoxide add <path>       Add/increment path without visiting
#   zoxide query <term>     Search database
#   zoxide query -s         Show scores with results
#   zoxide query -l         List all entries
#   zoxide query -ls        List all entries with scores (most useful!)
#   zoxide remove <path>    Delete path from database
#   zoxide edit             Interactive database editor (i/I to increment,
#                           d/D to decrement, x to remove, q to quit)
#
# ══════════════════════════════════════════════════════════════════════════════
# IMPORTING FROM OTHER TOOLS
# ══════════════════════════════════════════════════════════════════════════════
#
# If migrating from autojump, z, z.lua, fasd, or zsh-z:
#
#   zoxide import --from=autojump "/path/to/autojump.txt"
#   zoxide import --from=z "/path/to/.z"
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATIONS
# ══════════════════════════════════════════════════════════════════════════════
#
# Zoxide integrates with many tools. Notably:
#   - telescope.nvim: telescope-zoxide plugin
#   - vim/neovim: zoxide.vim plugin
#   - yazi: natively supported
#   - ranger: ranger-zoxide plugin
#   - fzf: used for interactive selection (cdi)
#
_: {
  flake.modules.homeManager.zoxide = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.zoxide = {
      enable = true;
      package = lib.mkDefault pkgs.zoxide;

      # ────────────────────────────────────────────────────────────────────────
      # Init options passed to `zoxide init <shell>`
      # ────────────────────────────────────────────────────────────────────────
      #
      # --cmd cd    Replace cd with zoxide while maintaining full compatibility:
      #             - `cd` alone returns to $HOME
      #             - `cd -` returns to previous directory
      #             - `cd <path>` works with relative/absolute paths
      #             - `cd <keyword>` enables smart jumping
      #             - `cdi` enables interactive fzf selection
      #
      # Available hooks (we use default 'pwd'):
      #   --hook pwd     Score directory on each directory change (default)
      #   --hook prompt  Score directory at every shell prompt
      #   --hook none    Never automatically score (manual only)
      #
      options = [
        "--cmd cd"
      ];

      # Shell integrations are automatically enabled by home-manager when the
      # corresponding shell program is enabled (e.g., programs.fish.enable = true).
      # See: lib.hm.shell.mk*IntegrationOption in home-manager source
    };

    # ══════════════════════════════════════════════════════════════════════════
    # XDG COMPLIANCE & ENVIRONMENT CONFIGURATION
    # ══════════════════════════════════════════════════════════════════════════
    #
    # By default on macOS, zoxide stores its database at:
    #   ~/Library/Application Support/zoxide/db.zo
    #
    # We override this to use XDG_DATA_HOME for consistency with other tools.
    # The database file will be at: ~/.local/share/zoxide/db.zo
    #
    home.sessionVariables = {
      # Store database in XDG data directory instead of macOS default
      _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";

      # Uncomment to print matched directory before navigating (useful for debugging)
      # _ZO_ECHO = "1";

      # Directories to exclude from the database (colon-separated globs)
      # $HOME is excluded by default; we add common non-project directories
      _ZO_EXCLUDE_DIRS = lib.concatStringsSep ":" [
        # ── Home & System ───────────────────────────────────────────────────
        "$HOME" # Default: don't track home directory itself
        "$HOME/Downloads/*" # Temporary download location
        "$HOME/Library/*" # macOS system directories
        "$HOME/Applications/*" # macOS user applications
        "$HOME/.Trash/*" # Trash
        "/tmp/*" # Temporary files
        "/private/tmp/*" # macOS tmp location
        "/private/var/*" # macOS system
        "/nix/*" # Nix store (read-only, not useful to track)

        # ── Version Control ─────────────────────────────────────────────────
        "*/.git/*" # Git internals

        # ── Build Artifacts & Dependencies ──────────────────────────────────
        "*/node_modules/*" # Node.js dependencies
        "*/.direnv/*" # direnv cached environments
        "*/target/*" # Rust/Cargo build output
        "*/dist/*" # Common build output
        "*/build/*" # Common build output
        "*/.build/*" # Swift build output
        "*/out/*" # Common build output

        # ── JavaScript/TypeScript Framework Caches ──────────────────────────
        "*/.next/*" # Next.js
        "*/.nuxt/*" # Nuxt.js
        "*/.output/*" # Nuxt 3
        "*/.svelte-kit/*" # SvelteKit
        "*/.turbo/*" # Turborepo
        "*/.parcel-cache/*" # Parcel
        "*/.cache/*" # Generic cache (Gatsby, etc.)

        # ── Python ──────────────────────────────────────────────────────────
        "*/__pycache__/*" # Python bytecode
        "*/.pytest_cache/*" # pytest
        "*/.mypy_cache/*" # mypy type checker
        "*/.ruff_cache/*" # ruff linter
        "*/.tox/*" # tox testing
        "*/.nox/*" # nox testing
        "*/.venv/*" # Virtual environments
        "*/venv/*" # Virtual environments (alternate)
        "*/.eggs/*" # Python eggs

        # ── IDE & Editor ────────────────────────────────────────────────────
        "*/.idea/*" # JetBrains IDEs
      ];

      # Custom fzf options for interactive selection (cdi)
      # Uses your fzf theme but adds useful preview
      _ZO_FZF_OPTS = lib.concatStringsSep " " [
        "$FZF_DEFAULT_OPTS" # Inherit default fzf options (colors, etc.)
        "--height=40%" # Don't take full screen
        "--layout=reverse" # List from top
        "--border" # Add border
        "--preview='eza --tree --level=1 --color=always --icons {2..}'" # Preview directory
        "--preview-window=right,40%" # Preview on right side
      ];

      # Maximum database size before aging/pruning occurs (default: 10000)
      # Higher = more entries retained, lower = more aggressive pruning
      # _ZO_MAXAGE = "10000";

      # Uncomment to resolve symlinks before adding to database
      # Useful if you access the same directory via different symlink paths
      # _ZO_RESOLVE_SYMLINKS = "1";
    };

    # Ensure the zoxide data directory exists
    home.activation.createZoxideDataDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${config.xdg.dataHome}/zoxide"
    '';
  };
}
