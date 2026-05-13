# Bun - all-in-one JavaScript runtime & toolkit
# https://github.com/nix-community/home-manager/blob/master/modules/programs/bun.nix
# https://bun.sh/docs/runtime/bunfig
#
# Git integration is automatically enabled based on whether git is active.
# This module reads config.programs.git.enable to coordinate.
_: {
  flake.modules.homeManager.bun = {config, ...}: {
    # ── XDG Compliance ──────────────────────────────────────────────────────────
    home.sessionVariables = {
      BUN_INSTALL = "${config.xdg.dataHome}/bun";
    };

    # ── PATH for Global Binaries ───────────────────────────────────────────────
    # Workaround: linker = "isolated" prevents bun from symlinking global binaries
    # into globalBinDir (~/.local/bin). The binaries end up only in node_modules/.bin/
    # within the global install directory.
    home.sessionPath = [
      "${config.xdg.dataHome}/bun/install/global/node_modules/.bin"
    ];

    programs.bun = {
      enable = true; # Bun - all-in-one JavaScript runtime & toolkit

      # Git integration for diffing bun.lockb files - derived from git being enabled
      enableGitIntegration = config.programs.git.enable;

      settings = {
        # ===== Privacy =====
        telemetry = false; # Disable analytics and crash reports

        # ===== Runtime =====
        smol = false; # Don't trade performance for memory (default)
        logLevel = "warn"; # Only show warnings and errors

        # ===== Console =====
        console = {
          depth = 4; # Deeper object inspection for debugging
        };

        # ===== Package Manager =====
        install = {
          # Version pinning
          exact = true; # Use exact versions in package.json for reproducibility
          saveTextLockfile = true; # Human-readable bun.lock for better git diffs

          # Linker strategy
          linker = "isolated"; # Stricter dependency resolution, prevents phantom deps

          # Global virtual store (bun 1.3.14+, experimental)
          # Materializes eligible packages once into <cache>/links/ and symlinks
          # node_modules/.bun/<pkg>@<ver> into it instead of clonefile-copying per project.
          # Massive speedup for warm installs on macOS APFS (eliminates clonefileat calls
          # that held a volume-wide kernel lock). Ineligible packages (patched, lifecycle
          # scripts, non-immutable sources) fall back to the `backend` strategy below.
          globalStore = true;

          # XDG-compliant directories
          globalDir = "${config.xdg.dataHome}/bun/install/global";
          globalBinDir = "${config.home.homeDirectory}/.local/bin";

          # Cache configuration
          cache = {
            dir = "${config.xdg.cacheHome}/bun/install/cache";
          };

          # Installation strategy - hardlink for Nix-like deduplication
          # Packages exist only once on disk, node_modules uses hardlinks
          backend = "hardlink";
        };

        # ===== Run Behavior =====
        run = {
          bun = false; # Don't auto-alias node to bun (safer for compatibility)
          silent = true; # Suppress "Running X..." messages for cleaner output
        };
      };
    };
  };
}
