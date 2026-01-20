# Task Tracker

> **Last Updated**: 2026-01-20

## Current Status

The dotfiles repository has been refactored to align with upstream nix-darwin and home-manager
conventions. Key achievements:

- **Flat structure**: All modules at root level (`modules/`, `programs/`, `hosts/`)
- **Auto-discovery**: New modules automatically imported via `lib/auto-discovery.nix`
- **Co-located assets**: Config files live with their modules (e.g., `programs/git/.gitmessage`)
- **Fish as default shell**: Full configuration with fzf integrations
- **1Password integration**: SSH agent + shell plugins for biometric auth
- **XDG compliance**: Tool-specific env vars co-located with program modules

See [ADR-005](./adr/005-home-manager-module-structure.md) for architecture decisions.

---

## 📋 To Do

- [ ] Merge PR #8 to main

---

## 🧊 Icebox (Future Improvements)

Potential enhancements, not currently prioritized:

- [ ] **Add more fish plugins** — fzf.fish, z, autopair.fish
- [ ] **Add Neovim/Helix configuration** — `programs/neovim/` or `programs/helix/`
- [ ] **Add tmux configuration** — `programs/tmux.nix`
- [ ] **Module testing patterns** — `_test.nix` convention
- [ ] **Documentation generation** — Auto-generate docs from module structure
- [ ] **Template for new modules** — `_template.nix` as starting point