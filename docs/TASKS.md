# Task Tracker

> **Last Updated**: 2026-02-22

## Current Status

The dotfiles repository uses a **dendritic architecture** with flake-parts:

- **Flake-parts modules**: Every `.nix` file is a flake-parts module
- **Cross-cutting features**: Modules co-locate darwin + HM concerns (fish, zsh, nushell, 1password, docker, zed)
- **import-tree auto-discovery**: New modules in `modules/features/` are automatically discovered
- **Typed host options**: `dotfiles.hosts.*` in `modules/options.nix`
- **Shared HM options**: `dotfiles.{hostname,sshKeys,onePasswordAgentSock}` bridge data between modules
- **No specialArgs**: All values flow through the module system
- **1Password integration**: SSH agent + shell plugins + shared keys via options

See [ADR-007](./adr/007-flake-parts-dendritic-migration.md) for architecture decisions.

---

## Open Discussions

- [ ] **Split the development environment from the configuration that is switched** (2026-11-16).
  One flake holds both: the `perSystem` devshell, formatter table and git hooks for working on
  this repo, and the darwin and Home Manager configurations that `just switch` applies. The
  question is whether the development side moves to devenv, as the team's repositories do.
  - For: the team's pattern; devenv's hooks are the same git-hooks.nix module, so the checks
    carry over unchanged.
  - Against: a second lock file means a second nixpkgs and more copies in the Nix store
    ([nix-store-sharing.md](./research/nix-store-sharing.md)).
  - Decided so far: settle the feedback loop first (`just lint` runs the git hooks at every
    stage), then revisit.

---

## Icebox (Future Improvements)

Potential enhancements, not currently prioritized:

- [ ] **Add more fish plugins** — fzf.fish, z, autopair.fish
- [ ] **Add Neovim/Helix configuration** — `modules/features/neovim/` or `modules/features/helix/`
- [ ] **Add tmux configuration** — `modules/features/tmux.nix`
- [ ] **Module testing patterns** — `_test.nix` convention
- [ ] **Documentation generation** — Auto-generate docs from module structure
