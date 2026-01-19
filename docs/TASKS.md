# Task Tracker: Home-Manager Module Structure Refactoring

> **Branch**: `refactor/structure-improvements`
> **Related ADR**: [ADR-005: Home-Manager Module Structure](./adr/005-home-manager-module-structure.md)
> **Started**: 2026-01

This document tracks the progress of the home-manager module structure refactoring effort.

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

---

## 🚧 In Progress

_No tasks currently in progress_

---

## 📋 To Do

### Phase 5: Additional Asset Co-location

- [ ] **Audit remaining assets in `config/`**
  - Review `config/` directory for other assets that should be co-located
  - Identify which programs would benefit from directory module pattern

- [ ] **Co-locate other program assets** (if applicable)
  - Move relevant config files to their program directories
  - Update modules to manage their own assets
  - Remove entries from `xdg.nix`

### Phase 6: Documentation & Cleanup

- [ ] **Update AGENTS.md**
  - Reflect new flat structure in architecture section
  - Update "Add a program" instructions
  - Document `_` prefix convention for draft modules

- [ ] **Update README.md**
  - Ensure project README reflects current structure
  - Add examples of both file and directory module patterns

- [ ] **Clean up `config/` directory**
  - Remove empty directories after asset migration
  - Document any remaining non-Nix configs and why they stay

### Phase 7: Validation & Merge

- [ ] **Run full validation**
  - `just fmt` - Format all files
  - `just lint` - Run statix linter
  - `just check` - Run all checks
  - `just build` - Build without applying
  - `just switch` - Apply and verify functionality

- [ ] **Squash/rebase commits** (optional)
  - Consider squashing related commits for cleaner history
  - Ensure commit messages are clear and follow conventions

- [ ] **Create PR / Merge to main**
  - Final review of all changes
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

---

## Notes

### Why This Refactoring?

1. **Upstream alignment**: Match official home-manager patterns
2. **Reduced friction**: Auto-discovery means no import maintenance
3. **Better organization**: Co-located assets are easier to understand
4. **Consistency**: Standard module signatures across all programs

### Key Files Changed

| File | Purpose |
|------|---------|
| `nix/home/programs/default.nix` | Auto-discovery logic |
| `nix/home/programs/git/default.nix` | Example directory module |
| `nix/home/programs/git/.gitmessage` | Co-located asset |
| `nix/home/users/common.nix` | Simplified imports |
| `nix/home/programs/xdg.nix` | Removed migrated symlinks |

### Commands Reference

```bash
# Format, lint, check
just fmt && just lint && just check

# Build and test
just build
just switch

# View git changes
git diff main..HEAD --stat
git log main..HEAD --oneline
```
