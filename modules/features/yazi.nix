# yazi - Blazing fast terminal file manager
# https://github.com/sxyazi/yazi
# https://yazi-rs.github.io/docs/installation
# https://github.com/nix-community/home-manager/blob/master/modules/programs/yazi.nix
# https://github.com/yazi-rs/plugins (official plugins)
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# Yazi is a blazing fast terminal file manager written in Rust, based on
# async I/O. It features built-in support for images, videos, PDFs, and
# archives with a highly customizable UI.
#
# Key features:
#   - Async I/O for blazing fast performance
#   - Built-in preview for images, videos, PDFs, archives
#   - Vim-like keybindings (hjkl navigation)
#   - Plugin system with Lua scripting
#   - Zoxide and fzf integration
#   - Batch operations and bulk rename
#   - Tabs support
#
# Prerequisites (required):
#   - file (for file type detection) - included in macOS
#
# Optional dependencies for enhanced features:
#   - ffmpeg (video thumbnails) - not included
#   - 7zip (archive extraction/preview) - added below
#   - jq (JSON preview) - already in home.nix
#   - poppler (PDF preview) - not included
#   - fd (file searching) - already in fd.nix
#   - rg/ripgrep (content searching) - already in home.nix
#   - fzf (quick navigation) - already in fzf.nix
#   - zoxide (history navigation) - already in zoxide.nix
#   - resvg (SVG preview)
#   - ImageMagick (Font, HEIC, JPEG XL preview)
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   yazi                       Open yazi in current directory
#   yazi <path>                Open yazi in specified path
#   y                          Open yazi with shell wrapper (cd on exit)
#
# Basic Navigation:
#   h / l                      Parent / Enter directory
#   j / k                      Down / Up
#   gg / G                     First / Last item
#   H / M / L                  Top / Middle / Bottom of screen
#
# Selection & Actions:
#   Space                      Toggle selection
#   V                          Visual mode (select range)
#   y                          Yank (copy)
#   x                          Cut
#   p                          Paste
#   P                          Paste (overwrite)
#   d                          Trash
#   D                          Permanently delete
#
# File Operations:
#   a                          Create file
#   A                          Create directory
#   r                          Rename
#   ;                          Run shell command
#   :                          Open command palette
#   .                          Toggle hidden files
#
# Tabs:
#   t                          New tab
#   1-9                        Switch to tab N
#   [  ]                       Previous / Next tab
#   Tab                        Switch to next tab
#
# Search & Filter:
#   /                          Search (forward)
#   ?                          Search (backward)
#   n / N                      Next / Previous match
#   f                          Filter
#   z                          Jump with zoxide
#   Z                          Jump with fzf
#
# Preview:
#   Enter                      Open file
#   ~                          Open help
#   w                          Toggle task manager
#   Ctrl+s                     Toggle sort order
#
# ══════════════════════════════════════════════════════════════════════════════
# SHELL WRAPPER
# ══════════════════════════════════════════════════════════════════════════════
#
# The shell wrapper 'y' (configurable via shellWrapperName) allows yazi to
# change the current directory when you quit. Without it, you'd exit to the
# directory where you started yazi.
#
# Usage: y [path]
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# yazi integrates with several tools from this configuration:
#   - zoxide: 'z' key for smart directory jumping
#   - fzf: 'Z' key for fuzzy directory search
#   - fd: File searching within yazi
#   - ripgrep: Content searching within yazi
#   - bat: Syntax highlighted file previews
#
_: {
  flake.modules.homeManager.yazi = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault attrByPath;

    # Helper to safely check if a shell program is enabled (defaults to false if not defined)
    shellEnabled = path: attrByPath path false config;
  in {
    programs.yazi = {
      enable = mkDefault true;
      package = mkDefault pkgs.yazi;

      # ────────────────────────────────────────────────────────────────────────
      # Shell Wrapper
      # ────────────────────────────────────────────────────────────────────────
      # Name of the shell function that wraps yazi to change directory on exit.
      # Default: "yy", changed to "y" for brevity
      shellWrapperName = "y";

      # ────────────────────────────────────────────────────────────────────────
      # Shell Integrations
      # ────────────────────────────────────────────────────────────────────────
      # Enable shell wrapper in configured shells.
      # The wrapper allows yazi to change the shell's working directory on exit.
      # Uses attrByPath for safe lookup with fallback to false if module not present.
      enableBashIntegration = mkDefault (shellEnabled ["programs" "bash" "enable"]);
      enableZshIntegration = mkDefault (shellEnabled ["programs" "zsh" "enable"]);
      enableFishIntegration = mkDefault (shellEnabled ["programs" "fish" "enable"]);
      enableNushellIntegration = mkDefault (shellEnabled ["programs" "nushell" "enable"]);

      # ────────────────────────────────────────────────────────────────────────
      # Settings (yazi.toml)
      # ────────────────────────────────────────────────────────────────────────
      # See: https://yazi-rs.github.io/docs/configuration/yazi
      settings = {
        mgr = {
          # Show hidden files by default
          show_hidden = true;
          # Sort directories before files
          sort_dir_first = true;
          # Default sort by name
          sort_by = "natural";
          # Line mode: "none", "size", "permissions", "mtime", etc.
          linemode = "size";
        };

        preview = {
          # Maximum preview dimensions
          max_width = 1000;
          max_height = 1000;
          # Use sixel/kitty protocol for image preview when available
          image_delay = 30;
        };

        # Custom openers
        opener = {
          # Use $VISUAL (zed) for GUI editing
          visual = [
            {
              run = ''$VISUAL "$@"'';
              orphan = true; # Don't block yazi
              desc = "Open in Zed";
              for = "macos";
            }
          ];
          # macOS wallpaper setter
          set-wallpaper = [
            {
              run = ''osascript -e 'on run {img}' -e 'tell application "System Events" to set picture of every desktop to img' -e 'end run' "$@"'';
              desc = "Set as wallpaper";
              for = "macos";
            }
          ];
        };

        # Use visual editor for text files by default
        open = {
          prepend_rules = [
            {
              mime = "text/*";
              use = ["visual" "edit"];
            }
            {
              mime = "application/json";
              use = ["visual" "edit"];
            }
            {
              mime = "application/x-nix";
              use = ["visual" "edit"];
            }
            # Set wallpaper for images
            {
              mime = "image/*";
              use = ["set-wallpaper" "open"];
            }
          ];
        };
      };

      # ────────────────────────────────────────────────────────────────────────
      # Keymap (keymap.toml)
      # ────────────────────────────────────────────────────────────────────────
      # See: https://yazi-rs.github.io/docs/configuration/keymap
      keymap = {
        mgr.prepend_keymap = [
          # ── Quick Look (macOS) ────────────────────────────────────────────
          {
            on = ["<C-p>"];
            run = "shell --confirm -- qlmanage -p \"$@\"";
            desc = "Preview with Quick Look";
          }

          # ── Git operations ────────────────────────────────────────────────
          {
            on = ["g" "r"];
            run = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
            desc = "cd to git root";
          }

          # ── Shell ─────────────────────────────────────────────────────────
          {
            on = ["!"];
            run = "shell \"$SHELL\" --block --confirm";
            desc = "Open shell here";
          }

          # ── Quit ──────────────────────────────────────────────────────────
          {
            on = ["Q"];
            run = "quit --no-cwd-file";
            desc = "Quit without changing directory";
          }
        ];

        # Close input with single Esc press (don't enter vi mode)
        input.prepend_keymap = [
          {
            on = ["<Esc>"];
            run = "close";
            desc = "Cancel input";
          }
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Theme (theme.toml)
      # ────────────────────────────────────────────────────────────────────────
      # See: https://yazi-rs.github.io/docs/configuration/theme
      # Use default theme; uncomment to customize
      theme = {};

      # ────────────────────────────────────────────────────────────────────────
      # Init Lua (init.lua)
      # ────────────────────────────────────────────────────────────────────────
      # Custom Lua initialization
      # See: https://yazi-rs.github.io/docs/configuration/yazi#init-lua
      initLua = ''
        -- Show symlink target in status bar
        Status:children_add(function(self)
          local h = self._current.hovered
          if h and h.link_to then
            return " -> " .. tostring(h.link_to)
          else
            return ""
          end
        end, 3300, Status.LEFT)
      '';

      # ────────────────────────────────────────────────────────────────────────
      # Plugins
      # ────────────────────────────────────────────────────────────────────────
      # See: https://yazi-rs.github.io/docs/plugins/overview
      #
      # Plugins are currently disabled to avoid build failures from external
      # GitHub dependencies. The official yazi-rs/plugins repository sometimes
      # has pinned commits that become unavailable, causing 404 errors during
      # nix builds.
      #
      # To re-enable plugins:
      # 1. Add a fetchFromGitHub block for yazi-rs/plugins with a stable commit
      # 2. Reference plugins in the plugins attribute below
      # 3. Add plugin-specific keybindings to keymap.mgr.prepend_keymap
      # 4. Initialize plugins in initLua with require("plugin-name"):setup()
      #
      # Previously used plugins:
      # - full-border: UI enhancement for cleaner borders
      # - toggle-pane: Maximize/minimize preview pane
      # - smart-enter: Combined enter directory/open file action
      # - git: Git status integration in file listing
      # - chmod: Interactive file permission changer
      plugins = {};

      # ────────────────────────────────────────────────────────────────────────
      # Flavors (themes)
      # ────────────────────────────────────────────────────────────────────────
      # See: https://yazi-rs.github.io/docs/flavors/overview
      # Flavors are linked to ~/.config/yazi/flavors/<name>.yazi
      flavors = {};
    };

    # ────────────────────────────────────────────────────────────────────────────
    # Optional Dependencies
    # ────────────────────────────────────────────────────────────────────────────
    # These packages enable additional preview and extraction features.
    # Note: fd, ripgrep, fzf, zoxide, bat, jq are already configured separately.
    #
    # Prerequisite: nixpkgs.config.allowUnfree = true (set in darwin.nix)
    home.packages = with pkgs; [
      # Archive extraction (with RAR support via unfree unrar)
      # Requires allowUnfree = true in nixpkgs config
      (p7zip.override {enableUnfree = true;})
      # Image format support (HEIC, JPEG XL, fonts)
      imagemagick
    ];
  };
}
