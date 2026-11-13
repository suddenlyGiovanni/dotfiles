# worktrunk (wt) - git worktree manager, with wt-sync for stacked branches
# https://worktrunk.dev
# https://github.com/pablospe/worktrunk-sync
# https://home-manager.dev/manual/unstable/options/home-manager/programs/worktrunk.html
#
# Installed for every repository on the machine, from nixpkgs-unstable. A project
# devshell may pin its own `wt` (headless does, ADR 0077 there); inside that
# project the devshell's copy comes first on PATH.
#
#   wt switch --create <branch>   new worktree and branch, then cd into it
#   wt list                       worktrees with their state
#   wt remove                     remove a worktree; refuses a dirty one
#   wt sync                       wt-sync: rebase a stack of worktree branches
#                                 onto their parents, in dependency order
#
# `wt sync` is no built-in: wt runs a `wt-<name>` program it finds on PATH, and
# worktrunk-sync provides `wt-sync`.
#
# WORKTREES LIVE INSIDE THE REPOSITORY
#
# wt's default puts a worktree next to the repository (`../<repo>.<branch>`).
# Here it goes to `.worktrees/<branch>`, the layout headless and this repository
# already use, and the one the Claude Code env hook trusts. A slash in the branch
# name stays a folder: `fix/login` lands in `.worktrees/fix/login`. git ignores
# `.worktrees/` everywhere (git/default.nix), so a repository needs no entry of
# its own. A project can still choose another place with WORKTRUNK_WORKTREE_PATH.
#
# THE CONFIG FILE IS READ-ONLY
#
# ~/.config/worktrunk/config.toml is generated from `settings` below. wt keeps
# what it writes by itself elsewhere (approvals of project hooks in
# approvals.toml), and `skip-shell-integration-prompt` stops the one prompt that
# would write to this file. Change a setting here, not with `wt config`.
#
# Shell integration (the `wt` function that lets `wt switch` change directory,
# and completions) comes from the module for each enabled shell: nu, fish, zsh
# and bash.
#
# ONE COPY OF THE NU INTEGRATION, NOT TWO
#
# The package also ships the nu integration as a vendor autoload file
# (share/nushell/vendor/autoload/wt.nu). nu loads autoload files after
# config.nu, so after the alias `open = ^open` (nushell/default.nix). The `wt`
# function in that file then calls macOS `open` where it means nu's built-in:
# `wt switch` prints "Switched" and stays in the old directory. The module's
# copy is sourced from config.nu before the aliases and works, but the autoload
# copy loads later and wins. So the package here is the nixpkgs one without
# that file.
#
# Not enabled: `claudeCodeIntegration`. It adds WorktreeCreate and WorktreeRemove
# hooks to Claude Code for every project, and headless ships its own.
_: {
  flake.modules.homeManager.worktrunk = {pkgs, ...}: let
    # A view of the package, not a rebuild: links to everything but the file.
    worktrunk = pkgs.symlinkJoin {
      name = "worktrunk-${pkgs.worktrunk.version}";
      paths = [pkgs.worktrunk];
      postBuild = ''
        rm $out/share/nushell/vendor/autoload/wt.nu
      '';
      inherit (pkgs.worktrunk) meta version;
    };
  in {
    programs.worktrunk = {
      enable = true;
      package = worktrunk;
      settings = {
        skip-shell-integration-prompt = true;
        worktree-path = ".worktrees/{{ branch }}";
      };
    };

    home.packages = [pkgs.worktrunk-sync];
  };
}
