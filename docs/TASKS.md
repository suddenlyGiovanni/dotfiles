# Task Tracker: Dotfiles Optimization

> **Branch**: `refactor/structure-improvements`
> **Related ADR**: [ADR-005: Home-Manager Module Structure](./adr/005-home-manager-module-structure.md)
> **Analysis**: [Upstream Pattern Analysis](./UPSTREAM-ANALYSIS.md)
> **Started**: 2025-01
> **Last Updated**: 2025-01-20

This document tracks the progress of optimizing this dotfiles repository to align with upstream
nix-darwin and home-manager conventions.

---

## ✅ Done

### Phase 1: Module Convention Adoption

- [x] **Standardize module signatures**
  - Add proper `{ config, lib, pkgs, ... }:` signatures to all modules
  - Use `inherit (lib) mkDefault;` pattern
  - Apply `mkDefault` to overridable values
  - Add descriptive header comments
  - Add section comments (`── ...`) for organization

- [x] **Fix module warnings**
  - Fix `zsh.nix` dotDir warning by using absolute path

- [x] **Organize packages in home.nix**
  - Group packages by category with comments
  - Alphabetize imports

### Phase 2: Flatten Directory Structure

- [x] **Remove subdirectory categorization**
  - Move `programs/dev/*.nix` → `programs/`
  - Move `programs/shell/*.nix` → `programs/`
  - Move `programs/terminal/*.nix` → `programs/`
  - Remove empty `dev/`, `shell/`, `terminal/` directories

### Phase 3: Auto-Discovery

- [x] **Implement module auto-discovery**
  - Create `programs/default.nix` with discovery logic
  - Create `modules/default.nix` with discovery logic
  - Extract shared logic to `lib/auto-discovery.nix`
  - Use `builtins.readDir` + `lib.filterAttrs` pattern
  - Exclude `default.nix` from discovery
  - Exclude `_` prefixed files (draft convention)

- [x] **Support directory modules**
  - Update discovery to handle both file and directory patterns
  - Convert `git.nix` to `git/default.nix`
  - Convert `fish.nix` to `fish/` directory
  - Convert `zed.nix` to `zed/` directory

### Phase 4: Asset Co-location

- [x] **Co-locate git assets**
  - Move `.gitmessage` → `programs/git/.gitmessage`
  - Update git module to manage symlink via `xdg.configFile`

- [x] **Co-locate Zed configuration**
  - Created `programs/zed/default.nix` module
  - Moved `settings.json`, `keymap.json`, `tasks.json` → `programs/zed/`

- [x] **Co-locate environment variables with program modules**
  - `nodejs.nix`: NPM_CONFIG_*, NODE_REPL_HISTORY + packages
  - `rustup.nix`: CARGO_HOME, RUSTUP_HOME + package
  - `awscli.nix`: AWS_CONFIG_FILE, AWS_SHARED_CREDENTIALS_FILE + package
  - `docker.nix`: DOCKER_CONFIG + Docker CLI tools
  - `python.nix`: PYTHONSTARTUP, PYTHON_HISTORY + uv
  - `claude-code.nix`: CLAUDE_CONFIG_DIR + package
  - `bun.nix`: BUN_INSTALL env var
  - Simplified `session.nix`: Only global settings (EDITOR, PAGER, etc.)

### Phase 5: Flake Consolidation

- [x] **Unify root and darwin flakes**
  - Merged `nix/darwin/flake.nix` into root `flake.nix`
  - Root flake now exposes: `darwinConfigurations`, `devShells`, `formatter`
  - Deleted `nix/darwin/flake.nix` and `nix/darwin/flake.lock`
  - Updated `justfile` to use `.` instead of `./nix/darwin`

### Phase 6: Flat Root Structure

- [x] **Remove redundant `nix/` prefix**
  - Moved `nix/darwin/hosts/` → `hosts/`
  - Moved `nix/darwin/modules/` → `modules/`
  - Moved `nix/darwin/configuration.nix` → `darwin.nix`
  - Moved `nix/home/programs/` → `programs/`
  - Moved `nix/home/users/common.nix` → `home.nix`
  - Moved `nix/nix.conf` → `nix.conf`
  - Deleted `nix/` directory entirely
  - Deleted `users/` directory (merged into `home.nix`)

### Phase 7: Explicit Module Coordination

- [x] **Replace hardcoded integration flags**
  - Modules now read `config.programs.<name>.enable`
  - Updated: starship, zoxide, fzf, eza, direnv, ghostty, bun
  - Shell integrations auto-disable if target shell/tool is disabled

### Phase 8: 1Password Integration

- [x] **Add 1Password shell plugins**
  - Added `onepassword-shell-plugins` flake input
  - Created `programs/1password.nix` with shell plugin configuration
  - Enabled plugins for `gh` and `awscli2` (biometric auth via `op plugin run`)
  - Configured `OP_CONFIG_DIR` and `SSH_AUTH_SOCK`

### Phase 9: Declarative SSH & GPG

- [x] **Create SSH module**
  - New `ssh.nix` manages `~/.ssh/config` declaratively
  - Configure hosts with dedicated keys
  - Set 1Password SSH agent as IdentityAgent

- [x] **Create GPG module**
  - New `gpg.nix` manages GnuPG with XDG-compliant homedir
  - Configure `gpg-agent.conf` with JetBrains IDE pinentry
  - Auto-fix directory permissions (chmod 700)

### Phase 10: macOS Settings Audit

- [x] **Audit system settings from defaults**
  - Read current macOS settings via `defaults read`
  - Compare with nix-darwin typed options
  - Identify gaps and imperative settings

- [x] **Add missing darwin modules**
  - `menuextra-clock.nix`: Menu bar clock (24h, day of week)
  - `screencapture.nix`: Screenshot settings (PNG, thumbnails)
  - `custom-preferences.nix`: Settings via CustomUserPreferences
    - Week starts on Monday
    - Full trackpad multi-touch gestures
    - Fn key behavior, login window state

- [x] **Update existing modules**
  - `finder.nix`: Added NewWindowTarget = Home
  - `nsglobaldomain.nix`: Reorganized, added keyboard/locale settings
  - `window-manager.nix`: Set HideDesktop, tiling margins

### Phase 11: Fish as Default Shell

- [x] **Set fish as default login shell**
  - `darwin.nix`: Set `users.users.<name>.shell = pkgs.fish`
  - `darwin.nix`: Add fish to `environment.shells`
  - `darwin.nix`: Enable `programs.fish` with vendor completions

- [x] **Modularize fish configuration**
  - Created `programs/fish/` directory structure:
    - `default.nix`: Main config, shell init, plugins (bass)
    - `abbreviations.nix`: Navigation, switch abbr
    - `aliases.nix`: ll, tree, cat, preview
    - `functions.nix`: fzf integrations (fe, fcd, gadd, gco, rg-fzf)

- [x] **Add fish integrations**
  - `fe`: Find and edit file with fzf + bat preview
  - `fcd`: Find directory and cd with fzf + eza preview
  - `gadd`: Interactive git add with diff preview
  - `gco`: Interactive git checkout with log preview
  - `rg-fzf`: Ripgrep search with fzf + bat preview
  - `help`: Command help with bat highlighting
  - `mkcd`: Create directory and cd into it

### Phase 12: Documentation

- [x] **Update all documentation**
  - Updated `README.md` with fish/1password sections, fixed paths
  - Updated `AGENTS.md` with fish/1password info, fixed paths
  - Updated `CUSTOMIZATION.md` with all new modules and examples
  - Updated `TASKS.md` (this file) with completed phases

- [x] **Add ADR-005**
  - Document home-manager module structure decisions
  - Record rationale for flat structure, auto-discovery, co-location

- [x] **Add statix configuration**
  - Created `statix.toml` to suppress false positive on fish functions

### Phase 13: Validation & Cleanup

- [x] **Fix all linter warnings**
  - Fixed deadnix warnings (unused bindings)
  - Fixed statix warnings (except false positive)
  - All checks pass: `just check`

- [x] **Build and activate**
  - `just build` succeeds
  - `just switch` activates on personal machine

---

## 🚧 In Progress

_No tasks currently in progress_

---

## 📋 To Do

### Final Steps

- [ ] **Update ADR-005 paths**
  - Change `nix/home/programs/` → `programs/` throughout

- [ ] **Update xdg-compliance-audit.md**
  - Mark completed items
  - Document new home-manager managed paths

- [ ] **Merge to main**
  - Review PR description
  - Merge `refactor/structure-improvements` → `main`

---

## 🧊 Icebox (Future Improvements)

These are potential future enhancements, not part of the current refactoring:

- [ ] **Add more fish plugins**
  - Consider: fzf.fish, z, autopair.fish

- [ ] **Add Neovim/Helix configuration**
  - Create `programs/neovim/` or `programs/helix/` directory module

- [ ] **Add tmux configuration**
  - Create `programs/tmux.nix` module

- [ ] **Module testing patterns**
  - Create `_test.nix` convention for module tests
  - Explore nix-based testing for configurations

- [ ] **Documentation generation**
  - Auto-generate docs from module structure
  - List all managed programs with their options

- [ ] **Template for new modules**
  - Create `_template.nix` as a starting point for new programs

---

## Notes

### Final Directory Structure

```
dotfiles/
├── flake.nix                # Unified flake (darwin + dev environment)
├── flake.lock               # Pinned inputs
├── darwin.nix               # Darwin system configuration
├── home.nix                 # Home-manager user configuration
├── nix.conf                 # Nix configuration
├── justfile                 # Task runner
├── statix.toml              # Linter config
├── hosts/                   # Machine-specific configs
│   ├── personal.nix
│   └── work.nix
├── lib/                     # Shared helpers
│   ├── default.nix
│   └── auto-discovery.nix
├── modules/                 # Darwin system modules (auto-discovered)
│   ├── default.nix
│   ├── dock.nix
│   ├── finder.nix
│   ├── homebrew.nix
│   ├── security.nix
│   ├── menuextra-clock.nix
│   ├── custom-preferences.nix
│   └── ...
├── programs/                # Home-manager programs (auto-discovered)
│   ├── default.nix
│   ├── 1password.nix
│   ├── bat.nix
│   ├── fish/
│   │   ├── default.nix
│   │   ├── abbreviations.nix
│   │   ├── aliases.nix
│   │   └── functions.nix
│   ├── git/
│   │   ├── default.nix
│   │   └── .gitmessage
│   ├── zed/
│   │   ├── default.nix
│   │   ├── settings.json
│   │   ├── keymap.json
│   │   └── tasks.json
│   └── ...
└── docs/
    ├── adr/
    ├── CUSTOMIZATION.md
    └── TASKS.md
```

### Key Achievements

1. **Flat structure**: No more `nix/` prefix or nested categorization
2. **Auto-discovery**: New modules are automatically included
3. **Co-located assets**: Config files live with their modules
4. **Explicit coordination**: Modules read `config.programs.<name>.enable`
5. **Fish as default**: Full shell configuration with fzf integrations
6. **1Password integration**: SSH agent + shell plugins for biometric auth
7. **macOS settings**: Comprehensive darwin defaults from system audit
8. **Documentation**: All docs updated to match current state

### Commands Reference

```bash
# Format, lint, check
just check

# Build and apply
just build
just switch

# After switch, set fish as login shell
chsh -s /run/current-system/sw/bin/fish

# Show flake outputs
nix flake show
```
