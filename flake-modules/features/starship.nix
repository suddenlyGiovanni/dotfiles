# starship - A minimal, blazing-fast, and customizable prompt for any shell
# https://starship.rs/
# https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/starship.nix
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# Starship is a cross-shell prompt written in Rust. It's fast, customizable,
# and shows information you need while you're working, like:
#   - Current directory (with git repo awareness)
#   - Git branch and status
#   - Programming language versions (when in a project)
#   - Command duration (for long-running commands)
#   - Exit status of last command
#   - And much more...
#
# Key features:
#   - Blazingly fast: written in Rust with async module loading
#   - Highly customizable: configure every aspect of your prompt
#   - Universal: works with any shell (bash, zsh, fish, nushell, etc.)
#   - Intelligent: shows relevant info based on context
#
# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
#
# This configuration includes:
#   - Full Nerd Font Symbols Preset (https://starship.rs/presets/nerd-font)
#   - Custom character indicators for command success/failure
#   - Git integration with metrics (lines added/removed)
#   - Command duration display
#   - Directory truncation with repo awareness
#   - Shell indicator (fish, zsh, bash, etc.)
#   - Language/tool version display
#   - Transient prompt for fish (cleaner history)
#
# ══════════════════════════════════════════════════════════════════════════════
# SHELL INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Shell integrations are automatically enabled based on which shells are active
# in your home-manager configuration. This module reads config.programs.<shell>.enable
# to coordinate.
#
# Transient prompt (fish only):
#   When enabled, previous prompts are replaced with a minimal prompt,
#   keeping your terminal history clean and focused.
#
# ══════════════════════════════════════════════════════════════════════════════
# CUSTOMIZATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Format strings use special syntax:
#   $variable           Insert a variable's value
#   [text](style)       Apply style to text
#   (conditional)       Only show if variables inside are non-empty
#
# Style strings:
#   bold, italic, underline, dimmed, inverted
#   fg:color, bg:color (color names or hex like #ff0000)
#   ANSI color numbers (0-255)
#
# To customize further, modify the `settings` attribute below.
# See https://starship.rs/config/ for all available options.
#
_: {
  flake.modules.homeManager.starship = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) attrByPath mkDefault;

    # Safe lookup for shell enable flags with fallback to false
    # This prevents evaluation failures if a shell module isn't imported
    shellEnabled = path: attrByPath path false config;
  in {
    programs.starship = {
      enable = true;
      package = mkDefault pkgs.starship;

      # ────────────────────────────────────────────────────────────────────────
      # Shell Integrations
      # ────────────────────────────────────────────────────────────────────────
      # Automatically enabled based on which shells are configured.
      # This ensures starship is initialized in each shell you use.
      # Uses safe lookup with fallback to false if shell module isn't present.
      enableBashIntegration = mkDefault (shellEnabled ["programs" "bash" "enable"]);
      enableZshIntegration = mkDefault (shellEnabled ["programs" "zsh" "enable"]);
      enableFishIntegration = mkDefault (shellEnabled ["programs" "fish" "enable"]);
      enableNushellIntegration = mkDefault (shellEnabled ["programs" "nushell" "enable"]);

      # ────────────────────────────────────────────────────────────────────────
      # Transient Prompt (Fish only)
      # ────────────────────────────────────────────────────────────────────────
      # Replaces previous prompts with a minimal version after command execution.
      # This keeps your terminal history clean and easy to read.
      enableTransience = mkDefault (shellEnabled ["programs" "fish" "enable"]);

      # ────────────────────────────────────────────────────────────────────────
      # Starship Configuration
      # ────────────────────────────────────────────────────────────────────────
      # Written to ~/.config/starship.toml
      settings = {
        # ══════════════════════════════════════════════════════════════════════
        # PROMPT-WIDE SETTINGS
        # ══════════════════════════════════════════════════════════════════════

        # Don't add a blank line before the prompt
        add_newline = false;

        # Use the default format (shows all enabled modules)
        # You can customize this to reorder or exclude modules
        format = "$all";

        # Timeout for starship to scan files (ms)
        scan_timeout = 30;

        # Timeout for commands executed by starship (ms)
        command_timeout = 500;

        # ══════════════════════════════════════════════════════════════════════
        # CHARACTER MODULE
        # ══════════════════════════════════════════════════════════════════════
        # Shows different symbols based on the success/failure of the last command

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vimcmd_symbol = "[❮](bold green)";
          vimcmd_replace_one_symbol = "[❮](bold purple)";
          vimcmd_replace_symbol = "[❮](bold purple)";
          vimcmd_visual_symbol = "[❮](bold yellow)";
        };

        # ══════════════════════════════════════════════════════════════════════
        # DIRECTORY MODULE
        # ══════════════════════════════════════════════════════════════════════

        directory = {
          disabled = false;
          # Truncate to 3 parent folders
          truncation_length = 3;
          # Truncate to git repo root when in a repo
          truncate_to_repo = true;
          # Symbol for truncated path
          truncation_symbol = "…/";
          # Read-only indicator
          read_only = " 󰌾";
          # Format string
          format = "[$path]($style)[$read_only]($read_only_style) ";
          # Style for the path
          style = "bold cyan";
          # Home directory symbol
          home_symbol = "~";
        };

        # ══════════════════════════════════════════════════════════════════════
        # GIT MODULES
        # ══════════════════════════════════════════════════════════════════════

        git_branch = {
          symbol = " ";
          style = "bold purple";
          # Truncate long branch names
          truncation_length = 20;
          truncation_symbol = "…";
        };

        git_commit = {
          tag_symbol = "  ";
          # Show commit hash only when detached
          only_detached = true;
          # Show tags
          tag_disabled = false;
        };

        git_state = {
          # Show progress during rebase, merge, etc.
          format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
          style = "bold yellow";
        };

        git_status = {
          # Show detailed git status
          format = "([\\[$all_status$ahead_behind\\]]($style) )";
          style = "bold red";
          # Status indicators
          conflicted = "=";
          ahead = "⇡\${count}";
          behind = "⇣\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          up_to_date = "";
          untracked = "?\${count}";
          stashed = "\\$";
          modified = "!\${count}";
          staged = "+\${count}";
          renamed = "»\${count}";
          deleted = "✘\${count}";
        };

        # Git metrics: show lines added/removed
        git_metrics = {
          disabled = false;
          added_style = "bold green";
          deleted_style = "bold red";
          # Only show when there are changes
          only_nonzero_diffs = true;
          format = "([+$added]($added_style) )([-$deleted]($deleted_style) )";
        };

        # ══════════════════════════════════════════════════════════════════════
        # COMMAND DURATION
        # ══════════════════════════════════════════════════════════════════════

        cmd_duration = {
          # Show duration for commands taking longer than 2 seconds
          min_time = 2000;
          # Format string
          format = "took [$duration]($style) ";
          style = "bold yellow";
          # Show milliseconds for short durations
          show_milliseconds = false;
        };

        # ══════════════════════════════════════════════════════════════════════
        # SHELL INDICATOR
        # ══════════════════════════════════════════════════════════════════════

        shell = {
          disabled = false;
          format = "[$indicator]($style) ";
          style = "bold white";
          # Shell-specific indicators
          fish_indicator = "󰈺";
          zsh_indicator = "zsh";
          bash_indicator = "bsh";
          powershell_indicator = "psh";
          nu_indicator = "nu";
          unknown_indicator = "?";
        };

        # ══════════════════════════════════════════════════════════════════════
        # STATUS MODULE (Exit Codes)
        # ══════════════════════════════════════════════════════════════════════

        status = {
          disabled = false;
          format = "[$symbol$status]($style) ";
          symbol = " ";
          style = "bold red";
          # Map exit codes to signals
          recognize_signal_code = true;
          # Use different symbols for different error types
          map_symbol = true;
          not_executable_symbol = "🚫";
          not_found_symbol = "🔍";
          sigint_symbol = "🧱";
          signal_symbol = "⚡";
        };

        # ══════════════════════════════════════════════════════════════════════
        # DIRENV MODULE
        # ══════════════════════════════════════════════════════════════════════

        direnv = {
          disabled = false;
          format = "[$symbol$loaded/$allowed]($style) ";
          symbol = " ";
          style = "bold orange";
          # Detection
          detect_files = [".envrc"];
          detect_env_vars = ["DIRENV_FILE"];
          # Status messages
          allowed_msg = "✓";
          not_allowed_msg = "✗";
          denied_msg = "✗";
          loaded_msg = "✓";
          unloaded_msg = "✗";
        };

        # ══════════════════════════════════════════════════════════════════════
        # CONTAINER MODULE
        # ══════════════════════════════════════════════════════════════════════

        container = {
          format = "[$symbol \\[$name\\]]($style) ";
          symbol = "⬢";
          style = "bold red dimmed";
        };

        # ══════════════════════════════════════════════════════════════════════
        # HOSTNAME & USERNAME (SSH Awareness)
        # ══════════════════════════════════════════════════════════════════════

        hostname = {
          # Only show when connected via SSH
          ssh_only = true;
          ssh_symbol = " ";
          format = "[$ssh_symbol$hostname]($style) in ";
          style = "bold dimmed green";
        };

        username = {
          # Only show when not the default user or when connected via SSH
          show_always = false;
          format = "[$user]($style) @ ";
          style_root = "bold red";
          style_user = "bold yellow";
        };

        # ══════════════════════════════════════════════════════════════════════
        # NERD FONT SYMBOLS - Language & Tool Modules
        # ══════════════════════════════════════════════════════════════════════
        # From: https://starship.rs/presets/nerd-font

        aws.symbol = "  ";
        azure.symbol = "󰠅 ";
        buf.symbol = " ";
        bun.symbol = " ";
        c.symbol = " ";
        cpp.symbol = " ";
        cmake.symbol = " ";
        conda.symbol = " ";
        crystal.symbol = " ";
        dart.symbol = " ";
        deno.symbol = " ";
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        fennel.symbol = " ";
        fortran.symbol = " ";
        fossil_branch.symbol = " ";
        gcloud.symbol = " ";
        gleam.symbol = "⭐ ";
        golang.symbol = " ";
        gradle.symbol = " ";
        guix_shell.symbol = " ";
        haskell.symbol = " ";
        haxe.symbol = " ";
        hg_branch.symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        kotlin.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        meson.symbol = "󰔷 ";
        nim.symbol = "󰆥 ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        ocaml.symbol = " ";
        package.symbol = "󰏗 ";
        perl.symbol = " ";
        php.symbol = " ";
        pijul_channel.symbol = " ";
        pixi.symbol = "󰏗 ";
        python.symbol = " ";
        rlang.symbol = "󰟔 ";
        ruby.symbol = " ";
        rust.symbol = "󱘗 ";
        scala.symbol = " ";
        swift.symbol = " ";
        xmake.symbol = " ";
        zig.symbol = " ";

        # ══════════════════════════════════════════════════════════════════════
        # NERD FONT SYMBOLS - OS Symbols
        # ══════════════════════════════════════════════════════════════════════
        # From: https://starship.rs/presets/nerd-font

        os.symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          AOSC = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Elementary = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Ios = "󰀷 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
          Zorin = " ";
        };

        # ══════════════════════════════════════════════════════════════════════
        # DISABLED MODULES (Enable if needed)
        # ══════════════════════════════════════════════════════════════════════
        # These modules are disabled by default but can be enabled by setting
        # disabled = false

        # Battery indicator (useful for laptops)
        # battery = {
        #   disabled = false;
        #   full_symbol = "󰁹 ";
        #   charging_symbol = "󰂄 ";
        #   discharging_symbol = "󰂃 ";
        #   unknown_symbol = "󰁽 ";
        #   empty_symbol = "󰂎 ";
        # };

        # Time display
        # time = {
        #   disabled = false;
        #   format = "at [$time]($style) ";
        #   time_format = "%R"; # 24-hour format
        #   style = "bold yellow";
        # };

        # Kubernetes context
        # kubernetes = {
        #   disabled = false;
        #   format = "on [⛵ $context( \\($namespace\\))]($style) ";
        #   style = "cyan bold";
        # };

        # Memory usage (shows when > 75%)
        # memory_usage = {
        #   disabled = false;
        #   threshold = 75;
        #   format = "via $symbol [$ram( | $swap)]($style) ";
        #   style = "bold dimmed white";
        # };
      };
    };
  };
}
