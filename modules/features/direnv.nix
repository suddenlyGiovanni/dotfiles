# direnv - Load and unload environment variables depending on the current directory
# https://github.com/nix-community/home-manager/blob/master/modules/programs/direnv.nix
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
_: {
  flake.modules.homeManager.direnv = {
    config,
    lib,
    ...
  }: let
    # Safe lookup for shell enable flags with fallback to false
    # This prevents evaluation failures if a shell module isn't imported
    shellEnabled = path: lib.attrByPath path false config;
  in {
    programs.direnv = {
      enable = true;

      # Shell integrations - derived from enabled shells
      # Uses safe lookup with fallback to false if shell module isn't present
      enableBashIntegration = shellEnabled ["programs" "bash" "enable"];
      enableZshIntegration = shellEnabled ["programs" "zsh" "enable"];
      enableFishIntegration = shellEnabled ["programs" "fish" "enable"];
      enableNushellIntegration = shellEnabled ["programs" "nushell" "enable"];

      # Fast, persistent use_nix implementation for direnv
      nix-direnv.enable = true;

      # ~/.config/direnv/direnvrc
      #
      # Share the nix-direnv flake-profile cache across all worktrees of a
      # repo. By default direnv keys its layout dir on $PWD, so every Claude
      # worktree under .claude/worktrees/<name> pays a cold `nix print-dev-env`
      # on first load and writes its own copy of the env dump — even though
      # that dump is worktree-independent (only $out/$prefix differ, and those
      # are unused in a devshell). Point every worktree of a checkout at the
      # MAIN checkout's .direnv instead, keyed on the git common dir.
      #
      # Safe by construction:
      #   - Outside a git repo: no-op (falls back to the $PWD/.direnv default).
      #   - Normal single checkout: unchanged (its common dir IS $PWD/.git).
      #   - Worktree on a branch with a different flake.lock: still gets its own
      #     flake-profile-<hash>.rc in the shared dir (hash differs) — never stale.
      stdlib = ''
        direnv_layout_dir() {
          local git_dir
          if git_dir=$(git rev-parse --git-common-dir 2>/dev/null); then
            echo "$(dirname "$(cd "$git_dir" && pwd)")/.direnv"
          else
            echo "$PWD/.direnv"
          fi
        }
      '';

      # ~/.config/direnv/direnv.toml
      #
      # Auto-trust agent-created git worktrees. Claude Code spawns
      # worktrees under <repo>/.claude/worktrees/<name> via a codepath
      # that does NOT fire its WorktreeCreate hook, so each fresh worktree
      # would otherwise need a manual `direnv allow`. A prefix whitelist
      # matches on the .envrc's absolute path, implicitly allowing every
      # nested worktree regardless of content hash.
      #
      # SECURITY: any .envrc placed under a whitelisted prefix is executed
      # by direnv with no prompt. Acceptable for local, agent-owned dirs;
      # do not extend these prefixes to shared or untrusted locations.
      config.whitelist.prefix = [
        "${config.home.homeDirectory}/Developer/work/headless-but/.claude/worktrees"
      ];
    };
  };
}
