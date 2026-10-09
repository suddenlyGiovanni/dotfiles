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
      # Forward-port of nix-direnv PR #790 (fixes issue #786) — remove once a
      # nix-direnv release past 3.2.0 ships it.
      #
      # nix-direnv both watches and touches its own cache file: use_flake
      # registers flake-profile-<hash>.rc with watch_file, while on every
      # cache-hit load _nix_refresh_gcroots runs
      #   touch -h .direnv/flake-profile-* ...
      # whose glob also matches that watched .rc. Touched + watched means each
      # load invalidates every OTHER shell's watch state, so two or more
      # terminals (or Claude Code hook invocations) on one repo ping-pong each
      # other into spurious reloads forever. The touch only existed to shield
      # gc-root symlinks from nh's age-based cleaning, which modern
      # `nh clean --keep-one` obsoletes — upstream's fix is to drop the
      # refresh outright; nh is not installed here anyway. direnv sources
      # lib/*.sh before this direnvrc, so this no-op shadows nix-direnv's
      # definition.
      #
      # History: this slot previously overrode direnv_layout_dir to point every
      # git worktree at the main checkout's .direnv (commit d98acd5), keyed on
      # the git common dir. That sharing was built on a false premise — the
      # profile hash is sha1 of the flake *expression* (always "."), not of the
      # flake inputs — so all worktrees collided on one cache file and one
      # gc-root, amplifying the #786 reload storm across every open session and
      # exposing divergent worktrees to wrong-env serving and GC of their live
      # toolchain. Retired 2026-08-24: worktree isolation is the headless
      # repo's documented contract (docs/git-worktree-guide.md), and on
      # Determinate Nix with lazy-trees a per-worktree devshell eval costs
      # <1s + ~116KB — sharing bought nothing the nix store doesn't already
      # provide.
      stdlib = ''
        _nix_refresh_gcroots() {
          # no-op: see the module comment (nix-direnv #786 / #790)
          :
        }
      '';

      # ~/.config/direnv/direnv.toml
      #
      # Auto-trust git worktrees under the headless monorepo. headless keeps
      # every worktree (`just worktree add`, Claude Code, Zed) under the main
      # checkout's .worktrees/ (its docs/git-worktree-guide.md); older Claude
      # Code worktrees stay under .claude/worktrees/ until they are removed.
      # Fresh `--worktree` sessions are allowed + bootstrapped by the repo's
      # WorktreeCreate hook, and its SessionStart hook re-allows the cwd; the
      # whitelist covers what those cannot: worktrees made by `just worktree`
      # or Zed, interactively cd-ing into a worktree without a manual
      # `direnv allow`, and allow entries dropped by `direnv prune`. A prefix
      # whitelist matches on the .envrc's absolute path, implicitly allowing
      # every nested worktree regardless of content hash.
      #
      # SECURITY: any .envrc placed under a whitelisted prefix is executed
      # by direnv with no prompt — that includes a branch checked out by hand
      # into .worktrees/. Acceptable for local dirs; do not extend these
      # prefixes to shared or untrusted locations.
      config.whitelist.prefix = [
        "${config.home.homeDirectory}/Developer/work/headless/.worktrees"
        "${config.home.homeDirectory}/Developer/work/headless/.claude/worktrees"
      ];
    };
  };
}
