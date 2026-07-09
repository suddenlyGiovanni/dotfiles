# fzf - A command-line fuzzy finder
# https://github.com/junegunn/fzf
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fzf.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# fzf is a general-purpose command-line fuzzy finder. It's an interactive filter
# program for any kind of list: files, command history, processes, hostnames,
# bookmarks, git commits, etc. It implements a "fuzzy" matching algorithm, so
# you can quickly type in patterns with omitted characters and still get results.
#
# ══════════════════════════════════════════════════════════════════════════════
# KEYBINDINGS (Shell Integration) - macOS
# ══════════════════════════════════════════════════════════════════════════════
#
#   ⌃T (Ctrl-T)    Paste selected files/directories onto command line
#                  e.g., `vim <⌃T>` → select file → `vim selected_file.txt`
#
#   ⌃R (Ctrl-R)    Search command history and paste selected command
#                  Press ⌃R again to toggle sort by relevance/chronological
#
#   ⌥C (Option-C)  cd into selected directory
#                  Uses fd to respect .gitignore and skip common junk directories
#
# ══════════════════════════════════════════════════════════════════════════════
# FUZZY COMPLETION (bash/zsh/fish)
# ══════════════════════════════════════════════════════════════════════════════
#
# Trigger fuzzy completion with `**<TAB>`:
#
#   vim **<TAB>           Files under current directory (multi-select with TAB)
#   vim ../**<TAB>        Files under parent directory
#   cd **<TAB>            Directories only
#   cd ~/github/fzf**<TAB>  Directories matching pattern
#   kill -9 **<TAB>       Process IDs (multi-select supported)
#   ssh **<TAB>           Hostnames from /etc/hosts and ~/.ssh/config
#   export **<TAB>        Environment variables
#   unset **<TAB>         Environment variables
#   unalias **<TAB>       Aliases
#
# ══════════════════════════════════════════════════════════════════════════════
# SEARCH SYNTAX
# ══════════════════════════════════════════════════════════════════════════════
#
#   Token     │ Match type                 │ Description
#   ──────────┼────────────────────────────┼────────────────────────────────────
#   sbtrkt    │ fuzzy-match                │ Items that match `sbtrkt`
#   'wild     │ exact-match (quoted)       │ Items that include `wild`
#   ^music    │ prefix-exact-match         │ Items that start with `music`
#   .mp3$     │ suffix-exact-match         │ Items that end with `.mp3`
#   !fire     │ inverse-exact-match        │ Items that do not include `fire`
#   !^music   │ inverse-prefix-exact-match │ Items that do not start with `music`
#   !.mp3$    │ inverse-suffix-exact-match │ Items that do not end with `.mp3`
#
# Multiple terms are AND'd together. Use `|` for OR:
#   ^core go$ | rb$ | py$    →  starts with 'core' AND ends with go/rb/py
#
# ══════════════════════════════════════════════════════════════════════════════
# NAVIGATION - macOS
# ══════════════════════════════════════════════════════════════════════════════
#
#   ⌃J / ⌃N        Move cursor down
#   ⌃K / ⌃P        Move cursor up
#   Enter (↩)      Select item
#   Tab (⇥)        Mark item (multi-select mode)
#   ⇧⇥ (Shift-Tab) Unmark item
#   ⌃C / Esc       Cancel
#
# ══════════════════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES
# ══════════════════════════════════════════════════════════════════════════════
#
#   FZF_DEFAULT_COMMAND    Default command when input is tty (no pipe)
#   FZF_DEFAULT_OPTS       Default options applied to all fzf invocations
#   FZF_CTRL_T_COMMAND     Command for ⌃T file widget
#   FZF_CTRL_T_OPTS        Options for ⌃T
#   FZF_CTRL_R_OPTS        Options for ⌃R history widget
#   FZF_ALT_C_COMMAND      Command for ⌥C directory widget
#   FZF_ALT_C_OPTS         Options for ⌥C
#
_: {
  flake.modules.homeManager.fzf = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;

    # Common directories to skip when searching (respects .gitignore by default with fd)
    walkerSkip = ".git,node_modules,target,.direnv,dist,build,.next,.nuxt,.svelte-kit,__pycache__,.venv,venv,.cache";
  in {
    programs.fzf = {
      enable = true;
      package = mkDefault pkgs.fzf;

      # ────────────────────────────────────────────────────────────────────────
      # Default Command
      # ────────────────────────────────────────────────────────────────────────
      # Command used when fzf is started without piped input.
      # Using fd instead of find for better performance and .gitignore support.
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

      # ────────────────────────────────────────────────────────────────────────
      # Default Options
      # ────────────────────────────────────────────────────────────────────────
      # Applied to all fzf invocations. Sets up layout, appearance, and behavior.
      # Note: Don't add --preview here as it breaks non-file inputs (ps, history)
      defaultOptions = [
        # Layout
        "--height=40%"
        "--layout=reverse"
        "--border=rounded"
        "--margin=0,1"

        # Info display
        "--info=inline-right"

        # Keybindings for preview window (⌃/ toggle, ⌃D/⌃U scroll)
        "--bind=ctrl-/:toggle-preview"
        "--bind=ctrl-d:preview-half-page-down"
        "--bind=ctrl-u:preview-half-page-up"

        # Multi-select
        "--multi"

        # Use path scheme for better file matching
        "--scheme=path"
      ];

      # ────────────────────────────────────────────────────────────────────────
      # ⌃T (Ctrl-T): File Widget
      # ────────────────────────────────────────────────────────────────────────
      # Paste selected files onto the command line.
      # Uses fd to respect .gitignore and skip common junk directories.
      fileWidget = {
        command = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
        options = [
          "--preview='bat --color=always --style=numbers --line-range=:500 {}'"
          "--preview-window=right,50%,border-left"
          "--walker-skip=${walkerSkip}"
          "--bind=ctrl-/:toggle-preview"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # ⌥C (Option-C): Change Directory Widget
      # ────────────────────────────────────────────────────────────────────────
      # cd into selected directory.
      # Uses fd to find directories, respecting .gitignore.
      changeDirWidget = {
        command = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
        options = [
          "--preview='eza --tree --level=2 --color=always --icons {}'"
          "--preview-window=right,50%,border-left"
          "--walker-skip=${walkerSkip}"
          "--bind=ctrl-/:toggle-preview"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # ⌃R (Ctrl-R): History Widget
      # ────────────────────────────────────────────────────────────────────────
      # Search and paste commands from history.
      historyWidget.options = [
        "--preview='echo {}'"
        "--preview-window=down,3,wrap,border-top"
        "--bind=ctrl-/:toggle-preview"
        # Use history scheme for chronological ordering
        "--scheme=history"
        # Sort by relevance initially (press ⌃R to toggle)
        "--bind=ctrl-r:toggle-sort"
      ];

      # ────────────────────────────────────────────────────────────────────────
      # Colors
      # ────────────────────────────────────────────────────────────────────────
      # Color scheme options added to FZF_DEFAULT_OPTS.
      # See: https://github.com/junegunn/fzf/wiki/Color-schemes
      # See: https://vitormv.github.io/fzf-themes/ (interactive theme builder)
      #
      # Leaving empty to use terminal colors. Uncomment to customize:
      # colors = {
      #   bg = "#1e1e2e";
      #   "bg+" = "#313244";
      #   fg = "#cdd6f4";
      #   "fg+" = "#cdd6f4";
      #   hl = "#f38ba8";
      #   "hl+" = "#f38ba8";
      #   info = "#cba6f7";
      #   marker = "#a6e3a1";
      #   prompt = "#89b4fa";
      #   spinner = "#f5e0dc";
      #   pointer = "#f5e0dc";
      #   header = "#94e2d5";
      #   border = "#6c7086";
      #   label = "#cdd6f4";
      #   query = "#cdd6f4";
      # };
      colors = {};

      # ────────────────────────────────────────────────────────────────────────
      # Tmux Integration
      # ────────────────────────────────────────────────────────────────────────
      # When enabled, fzf opens in a tmux popup instead of inline.
      # Silently ignored when not in tmux.
      tmux = {
        enableShellIntegration = false; # Set to true if you use tmux
        shellIntegrationOptions = [
          "-p" # popup
          "-w 80%"
          "-h 60%"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Shell Integrations
      # ────────────────────────────────────────────────────────────────────────
      # Automatically enabled by home-manager based on which shells are active.
      # This sets up CTRL-T, CTRL-R, ALT-C keybindings and ** completion.
      # See: lib.hm.shell.mk*IntegrationOption in home-manager source
    };
  };
}
