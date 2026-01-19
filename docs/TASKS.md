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

- [x] **Standardize module signatures** (`3fccb6d`)
  - Add proper `{ config, lib, pkgs, ... }:` signatures to all modules
  - Use `inherit (lib) mkDefault;` pattern
  - Apply `mkDefault` to overridable values
  - Add descriptive header comments
  - Add section comments (`── ...`) for organization

- [x] **Fix module warnings**
  - Fix `zsh.nix` dotDir warning by using absolute path

- [x] **Organize packages in common.nix**
  - Group packages by category with comments
  - Alphabetize imports

### Phase 2: Flatten Directory Structure

- [x] **Remove subdirectory categorization** (`1ea763e`)
  - Move `programs/dev/*.nix` → `programs/`
  - Move `programs/shell/*.nix` → `programs/`
  - Move `programs/terminal/*.nix` → `programs/`
  - Remove empty `dev/`, `shell/`, `terminal/` directories
  - Update README to reflect new flat structure

### Phase 3: Auto-Discovery

- [x] **Implement module auto-discovery** (`8235bfb`)
  - Create `programs/default.nix` with discovery logic
  - Use `builtins.readDir` + `lib.filterAttrs` pattern
  - Exclude `default.nix` from discovery
  - Exclude `_` prefixed files (draft convention)
  - Simplify `common.nix` imports to single `../programs` reference

- [x] **Support directory modules** (`41b067a`)
  - Update discovery to handle both file and directory patterns
  - Convert `git.nix` to `git/default.nix` as example
  - Update README to document both patterns

### Phase 4: Asset Co-location

- [x] **Co-locate git assets** (`d75c8d4`)
  - Move `config/git/.gitmessage` → `nix/home/programs/git/.gitmessage`
  - Update git module to manage symlink via `xdg.configFile`
  - Remove `.gitmessage` entry from `xdg.nix`

### Phase 5: Documentation

- [x] **Add ADR-005** (`b7f07f3`)
  - Document home-manager module structure decisions
  - Record rationale for flat structure, auto-discovery, co-location

- [x] **Create task tracker** (`b7f07f3`)
  - Initial TASKS.md with kanban-style tracking

- [x] **Upstream analysis** (`9e5882d`)
  - Analyze nix-darwin and home-manager source patterns
  - Document gaps and recommendations in UPSTREAM-ANALYSIS.md

### Phase 6: High Priority Fixes (Correctness)

- [x] **H1: Remove duplicate packages in `common.nix`** (`db3b8f0`)
  - Removed 21 duplicate package entries
  - Fixed pre-existing bug: duplicate `shellInit`/`loginShellInit` in fish.nix

- [x] **H2: Consolidate direnv configuration** (`db3b8f0`)
  - Removed `programs.direnv` block from `common.nix`
  - Fixed empty pattern warning in `direnv.nix` (`{...}:` → `_:`)
  - Configuration now only in `programs/direnv.nix`

### Phase 7: Medium Priority (Consistency)

- [x] **M1: Standardize `let` block formatting** (`85bc240`)
  - Updated all 13 program modules to use multi-line inherit with trailing semicolon
  - Files: bat, eza, fd, fish, fzf, gh, git, nushell, session, starship, xdg, zoxide, zsh

- [x] **M3: Split `system-defaults.nix`** (`fc01498`)
  - Split monolithic file into focused modules
  - Created `nix/darwin/modules/system-defaults/` directory
  - New files: activity-monitor, dock, finder, login-window, nsglobaldomain,
    software-update, spaces, trackpad, window-manager
  - Updated `configuration.nix` to import directory

### Phase 8: Asset Co-location & XDG Compliance

- [x] **Audit `config/` directory**
  - Found only Zed editor configs (settings.json, keymap.json, tasks.json)
  - Decided to co-locate with new `programs/zed/` module

- [x] **Co-locate Zed configuration** (`1c79b57`)
  - Created `nix/home/programs/zed/default.nix` module
  - Moved `config/zed/*.json` → `nix/home/programs/zed/`
  - Updated symlinks to use new paths with `mkOutOfStoreSymlink`
  - Removed Zed entries from `xdg.nix`
  - Deleted empty `config/` directory

- [x] **Co-locate environment variables with program modules** (`d509a57`)
  - Created new dedicated modules with XDG-compliant env vars:
    - `nodejs.nix`: NPM_CONFIG_*, NODE_REPL_HISTORY + packages
    - `rustup.nix`: CARGO_HOME, RUSTUP_HOME + package
    - `awscli.nix`: AWS_CONFIG_FILE, AWS_SHARED_CREDENTIALS_FILE + package
    - `docker.nix`: DOCKER_CONFIG + Docker CLI tools
    - `python.nix`: PYTHONSTARTUP, PYTHON_HISTORY + uv
    - `claude-code.nix`: CLAUDE_CONFIG_DIR + package
  - Updated `bun.nix`: Added BUN_INSTALL env var
  - Simplified `session.nix`: Only global settings (EDITOR, PAGER, SSH_AUTH_SOCK, etc.)
  - Updated `common.nix`: Removed packages now in dedicated modules

- [x] **Co-locate GitButler configuration** (`c6ab528`)
  - Created `gitbutler.nix` module for git config settings
  - Keep GitButler package in Homebrew (faster updates, binary distribution)
  - Moved `gitbutler.aiModelProvider` from git/default.nix to dedicated module

### Phase 8.5: XDG Home Directory Cleanup

- [x] **Clean up stale dotfiles** (`98d3d2c`)
  - Removed `~/.zcompdump` (now in `~/.cache/zsh/`)
  - Removed `~/.gitconfig` (merged GitButler settings into HM)
  - Removed `~/.bun` (2.3GB old cache, now using `~/.local/share/bun`)

- [x] **Migrate data to XDG locations**
  - Moved `~/.cargo/*` → `~/.local/share/cargo/`
  - Moved `~/.docker/*` → `~/.config/docker/`

- [x] **Additional cleanup** (done externally)
  - Removed `~/.gnupg` (migrated to `~/.local/share/gnupg`)
  - Removed `~/.lesshst`, `~/.viminfo`
  - Removed `~/.m2`, `~/.hawtjni`, `~/.junie`

### Phase 8.6: Declarative SSH & GPG Management

- [x] **Create SSH module** (`be2bac0`)
  - New `ssh.nix` manages `~/.ssh/config` declaratively
  - Configure `dev.thingos.io` host with dedicated key
  - Set 1Password SSH agent as IdentityAgent for all hosts

- [x] **Create GPG module** (`be2bac0`)
  - New `gpg.nix` manages GnuPG with XDG-compliant homedir
  - Configure `gpg-agent.conf` with JetBrains IDE pinentry
  - Configure `common.conf` with keyboxd setting
  - Include `pinentry-ide.sh` script for IDE integration
  - Auto-fix directory permissions (chmod 700)
  - Removed `GNUPGHOME` from `session.nix` (now via `programs.gpg.homedir`)

### Phase 9: Flake Consolidation

- [x] **Unify root and darwin flakes** (in progress)
  - Merged `nix/darwin/flake.nix` into root `flake.nix`
  - Root flake now exposes: `darwinConfigurations`, `devShells`, `formatter`
  - Updated all paths in flake to reference `./nix/darwin/...`
  - Deleted `nix/darwin/flake.nix` and `nix/darwin/flake.lock`
  - Updated `justfile` to use `.` instead of `./nix/darwin`
  - Updated lock file with new unified inputs

- [x] **Update documentation for flake consolidation**
  - Updated `AGENTS.md` with unified flake architecture
  - Updated `README.md` with new project structure and commands
  - Updated `docs/CUSTOMIZATION.md` with new paths and examples

---

## 🚧 In Progress

_No tasks currently in progress_

---

## 📋 To Do

### Phase 10: Validation & Merge

- [x] **Run full validation**
  - `just fmt` - Format all files ✅
  - `just lint` - Run statix linter ✅ (minor unused import warnings)
  - `just check` - Run all checks ✅
  - `just build` - Build without applying ✅
  - `just switch` - Apply and verify functionality (pending)

- [ ] **Final review**
  - Review all changes for consistency
  - Ensure no regressions in functionality

- [ ] **Update xdg-compliance-audit.md**
  - Mark completed items (Cargo, Docker, GnuPG, less, etc.)
  - Document new SSH and GPG home-manager management

- [ ] **Merge to main**
  - Squash/rebase commits if desired
  - Merge `refactor/structure-improvements` → `main`

---

## 🧊 Icebox (Future Improvements)

These are potential future enhancements, not part of the current refactoring:

- [ ] **Add `_lib.nix` for shared utilities**
  - Common functions used across multiple modules
  - Excluded from auto-discovery via `_` prefix

- [ ] **Convert more programs to directory pattern**
  - Candidates: programs with multiple config files or scripts
  - Examples: fish (functions), zsh (completions), neovim (plugins)

- [ ] **Add module testing patterns**
  - Create `_test.nix` convention for module tests
  - Explore nix-based testing for configurations

- [ ] **Documentation generation**
  - Auto-generate docs from module structure
  - List all managed programs with their options

- [ ] **Template for new modules**
  - Create `_template.nix` as a starting point for new programs
  - Include standard sections and conventions

- [ ] **Consider explicit module list**
  - Replace auto-discovery with explicit list for more control
  - Trade-off: More maintenance vs explicit ordering

- [ ] **Document `userConfig` pattern**
  - Add ADR explaining the custom `userConfig` specialArgs approach
  - Or migrate to standard `config.home.*` patterns

- [ ] **Fix unused import warnings**
  - Clean up unused `config` in: nushell.nix, zoxide.nix, gh.nix
  - Clean up unused `mkDefault` in: nodejs.nix, rustup.nix

- [ ] **Android SDK XDG compliance**
  - Add `ANDROID_USER_HOME` env var if doing Android development
  - Consider dedicated `android.nix` module

---

## Notes

### Why This Refactoring?

1. **Upstream alignment**: Match official nix-darwin and home-manager patterns
2. **Reduced friction**: Auto-discovery means no import maintenance
3. **Better organization**: Co-located assets and env vars are easier to understand
4. **Consistency**: Standard module signatures across all programs
5. **Portability**: Easier to set up on new machines
6. **Maintainability**: Removing a program removes all its config (no orphaned env vars)

### Key Files Changed

| File                                       | Purpose                                    |
| ------------------------------------------ | ------------------------------------------ |
| `flake.nix`                                | Unified flake (darwin + dev environment)   |
| `justfile`                                 | Updated to use root flake                  |
| `nix/home/programs/default.nix`            | Auto-discovery logic                       |
| `nix/home/programs/git/default.nix`        | Directory module with co-located asset     |
| `nix/home/programs/zed/default.nix`        | Directory module with co-located configs   |
| `nix/home/programs/nodejs.nix`             | Node.js + XDG env vars                     |
| `nix/home/programs/rustup.nix`             | Rust toolchain + XDG env vars              |
| `nix/home/programs/awscli.nix`             | AWS CLI + XDG env vars                     |
| `nix/home/programs/docker.nix`             | Docker tools + XDG env vars                |
| `nix/home/programs/python.nix`             | Python tools + XDG env vars                |
| `nix/home/programs/claude-code.nix`        | Claude Code + XDG env vars                 |
| `nix/home/programs/gitbutler.nix`          | GitButler git config (pkg via Homebrew)    |
| `nix/home/programs/ssh.nix`                | Declarative SSH client config              |
| `nix/home/programs/gpg.nix`                | Declarative GPG config + XDG compliance    |
| `nix/home/users/common.nix`                | Simplified imports, deduplicated           |
| `nix/home/programs/xdg.nix`                | Reduced to readline config only            |
| `nix/home/programs/session.nix`            | Global env vars only (EDITOR, PAGER, etc.) |
| `nix/darwin/modules/system-defaults/`      | Split macOS defaults (9 modules)           |
| `docs/UPSTREAM-ANALYSIS.md`                | Gap analysis and recommendations           |

### Files Removed

| File                                       | Reason                                     |
| ------------------------------------------ | ------------------------------------------ |
| `nix/darwin/flake.nix`                     | Merged into root `flake.nix`               |
| `nix/darwin/flake.lock`                    | Replaced by root `flake.lock`              |

### Home Directory Status (Post-Cleanup)

**XDG Compliant:**
- `~/.cache/` - XDG_CACHE_HOME
- `~/.config/` - XDG_CONFIG_HOME
- `~/.local/share/` - XDG_DATA_HOME
- `~/.local/state/` - XDG_STATE_HOME

**Home-Manager Managed:**
- `~/.ssh/config` - via `ssh.nix`
- `~/.local/share/gnupg/*` - via `gpg.nix`
- `~/.config/git/`, `~/.config/fish/`, etc. - via respective modules

**Remaining (acceptable):**
- `~/.1password/` - 1Password managed
- `~/.android/` - Android SDK
- `~/.codex/`, `~/.cagent/`, `~/.beads/`, `~/.expo/` - Various tools/agents
- `~/.nix-defexpr/`, `~/.nix-profile` - Nix system

### Upstream References

- [home-manager modules/programs/](https://github.com/nix-community/home-manager/tree/master/modules/programs)
- [nix-darwin modules/](https://github.com/nix-darwin/nix-darwin/tree/master/modules)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules)

### Commands Reference

```bash
# Format, lint, check
just fmt && just lint && just check

# Build and test (now uses root flake)
just build                    # darwin-rebuild build --flake .
just switch                   # sudo darwin-rebuild switch --flake .

# Show flake outputs
nix flake show                # Shows darwinConfigurations, devShells, formatter

# View git changes
git diff main..HEAD --stat
git log main..HEAD --oneline

# Inspect upstream repos
gh api repos/nix-community/home-manager/contents/modules/programs --jq '.[].name'
gh api repos/nix-darwin/nix-darwin/contents/modules --jq '.[].name'
```
