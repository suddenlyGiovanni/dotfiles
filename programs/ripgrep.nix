# ripgrep - A line-oriented search tool
# https://github.com/BurntSushi/ripgrep
# https://github.com/nix-community/home-manager/blob/master/modules/programs/ripgrep.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# ripgrep (rg) is a line-oriented search tool that recursively searches the
# current directory for a regex pattern. It's similar to grep but is designed
# to be faster and more user-friendly.
#
# Key features:
#   - Blazingly fast: uses Rust's regex engine with SIMD optimizations
#   - Respects .gitignore: automatically skips files in .gitignore
#   - Smart filtering: ignores hidden files, binary files by default
#   - Unicode support: full Unicode-aware regex matching
#   - Colored output: syntax-highlighted matches
#   - File type filtering: built-in support for many file types
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
# Basic search:
#   rg <pattern>               Search for pattern in current directory
#   rg <pattern> <path>        Search in specific file/directory
#   rg -i <pattern>            Case-insensitive search
#   rg -w <pattern>            Match whole words only
#   rg -F <pattern>            Treat pattern as literal string (not regex)
#
# Output control:
#   rg -c <pattern>            Count matches per file
#   rg -l <pattern>            List files with matches only
#   rg -o <pattern>            Print only matched parts
#   rg -C 3 <pattern>          Show 3 lines of context around matches
#   rg -B 2 -A 2 <pattern>     Show 2 lines before and after
#   rg --json <pattern>        Output as JSON (for tooling integration)
#
# File filtering:
#   rg -t rust <pattern>       Search only Rust files
#   rg -T js <pattern>         Exclude JavaScript files
#   rg -g '*.nix' <pattern>    Search only .nix files (glob)
#   rg -g '!*.lock' <pattern>  Exclude .lock files
#   rg --type-list             List all known file types
#
# Advanced:
#   rg -U <pattern>            Multi-line matching
#   rg -z <pattern>            Search compressed files
#   rg -r '$1' <pattern>       Replace matches with capture groups
#   rg --files                 List files that would be searched
#   rg -. <pattern>            Include hidden files (alias for --hidden)
#   rg -u <pattern>            Unrestricted: include ignored files
#   rg -uu <pattern>           Include hidden + ignored files
#   rg -uuu <pattern>          Include hidden + ignored + binary files
#
# ══════════════════════════════════════════════════════════════════════════════
# SMART CASE
# ══════════════════════════════════════════════════════════════════════════════
#
# With --smart-case enabled (default in this config):
#   - Patterns with only lowercase → case-insensitive search
#   - Patterns with any uppercase → case-sensitive search
#
# Examples:
#   rg foo          Matches: foo, Foo, FOO, fOo
#   rg Foo          Matches: Foo only
#   rg -s foo       Force case-sensitive: matches foo only
#   rg -i FOO       Force case-insensitive: matches foo, Foo, FOO
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# ripgrep is used throughout this configuration:
#   - batgrep (bat-extras): Search with ripgrep, display with bat highlighting
#   - fzf: Default grep command for fuzzy finding
#   - yazi: Content searching within the file manager
#   - rg-fzf fish function: Interactive search with preview
#   - Zed/editors: Often used as the search backend
#
# Related tools:
#   - fd.nix: File finding (like find)
#   - fzf.nix: Fuzzy finding
#   - bat.nix: Syntax-highlighted file viewing
#
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.ripgrep = {
    enable = true;
    package = mkDefault pkgs.ripgrep;

    # ────────────────────────────────────────────────────────────────────────
    # Configuration Arguments
    # ────────────────────────────────────────────────────────────────────────
    # These arguments are written to ~/.config/ripgrep/ripgreprc and applied
    # to every rg invocation via the RIPGREP_CONFIG_PATH environment variable.
    #
    # Each item is a single command-line argument. Use --flag=value syntax
    # for flags that take values on the same line.
    #
    # See: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
    arguments = [
      # ── Search Behavior ─────────────────────────────────────────────────

      # Smart case: case-insensitive unless pattern has uppercase letters
      # This is the most intuitive behavior for most searches
      "--smart-case"

      # ── Output Formatting ───────────────────────────────────────────────

      # Limit very long lines from being printed (e.g., minified JS)
      # Show a preview of the truncated line instead of skipping it
      "--max-columns=200"
      "--max-columns-preview"

      # Add blank line between results from different files
      # Makes output easier to scan
      "--heading"

      # Show line numbers in output
      "--line-number"

      # ── Glob Patterns ───────────────────────────────────────────────────
      # Exclude common directories that are rarely what you want to search
      # These supplement .gitignore rules (which rg respects by default)

      # Version control
      "--glob=!.git/*"
      "--glob=!.hg/*"
      "--glob=!.svn/*"

      # Dependencies and build artifacts
      "--glob=!node_modules/*"
      "--glob=!.direnv/*"
      "--glob=!target/*"
      "--glob=!dist/*"
      "--glob=!build/*"
      "--glob=!.build/*"
      "--glob=!out/*"

      # JavaScript/TypeScript framework caches
      "--glob=!.next/*"
      "--glob=!.nuxt/*"
      "--glob=!.output/*"
      "--glob=!.svelte-kit/*"
      "--glob=!.turbo/*"
      "--glob=!.parcel-cache/*"

      # Python caches
      "--glob=!__pycache__/*"
      "--glob=!.pytest_cache/*"
      "--glob=!.mypy_cache/*"
      "--glob=!.ruff_cache/*"
      "--glob=!.venv/*"
      "--glob=!venv/*"

      # Nix
      "--glob=!result"
      "--glob=!.devenv/*"

      # Lock files (usually not useful to search)
      "--glob=!*.lock"
      "--glob=!package-lock.json"
      "--glob=!pnpm-lock.yaml"
      "--glob=!yarn.lock"
      "--glob=!Cargo.lock"
      "--glob=!flake.lock"

      # Minified files
      "--glob=!*.min.js"
      "--glob=!*.min.css"

      # Source maps
      "--glob=!*.map"

      # ── Colors ──────────────────────────────────────────────────────────
      # Customize match highlighting for better visibility
      # Bold style for line numbers makes them easier to spot

      "--colors=line:style:bold"

      # ── Custom File Types ───────────────────────────────────────────────
      # Add custom type definitions for file types not built into ripgrep
      # Use with: rg -t nix <pattern>

      # Nix language files
      "--type-add=nix:*.nix"

      # Justfiles
      "--type-add=just:justfile"
      "--type-add=just:Justfile"
      "--type-add=just:*.just"

      # Fish shell
      "--type-add=fish:*.fish"

      # Zed editor config
      "--type-add=zed:*.json"
    ];
  };
}
