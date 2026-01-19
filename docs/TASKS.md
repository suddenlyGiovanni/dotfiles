# Task Tracker: Dotfiles Optimization

> **Branch**: `refactor/structure-improvements`
> **Related ADR**: [ADR-005: Home-Manager Module Structure](./adr/005-home-manager-module-structure.md)
> **Analysis**: [Upstream Pattern Analysis](./UPSTREAM-ANALYSIS.md)
> **Started**: 2026-01

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

- [x] **Upstream analysis** (`current`)
  - Analyze nix-darwin and home-manager source patterns
  - Document gaps and recommendations in UPSTREAM-ANALYSIS.md

---

## 🚧 In Progress

_No tasks currently in progress_

---

## 📋 To Do

### Phase 6: High Priority Fixes (Correctness)

- [ ] **H1: Remove duplicate packages in `common.nix`**
  - Duplicates found: `_1password-cli`, `alejandra`, `nixd`, `awscli2`, `container`,
    `dive`, `docker-buildx`, `docker-slim`, `lazydocker`, `nodejs_24`, `pnpm`,
    `biome`, `uv`, `rustup`, `cocoapods`, `glow`, `httpie`, `jq`, `just`,
    `shellcheck`, `shfmt`
  - Remove the duplicate entries at the bottom of the list

- [ ] **H2: Consolidate direnv configuration**
  - Remove `programs.direnv` block from `common.nix`
  - Keep configuration only in `programs/direnv.nix`
  - Verify direnv still works after change

### Phase 7: Medium Priority (Consistency)

- [ ] **M1: Standardize `let` block formatting**
  - Update all modules to use multi-line inherit with trailing semicolon
  - Example:
    ```nix
    let
      inherit (lib)
        mkDefault
        ;
    in
    ```
  - Files to update: All modules in `nix/home/programs/`

- [ ] **M2: Add `cfg` pattern to complex modules**
  - Add `cfg = config.programs.X;` to modules that reference their own config
  - Priority modules: `git/default.nix`, `zsh.nix`

- [ ] **M3: Consider splitting `system-defaults.nix`** (optional)
  - Split into: `dock.nix`, `finder.nix`, `trackpad.nix`, `nsglobaldomain.nix`
  - Create `system-defaults/default.nix` to import all
  - Trade-off: More files vs easier navigation

### Phase 8: Additional Asset Co-location

- [ ] **Audit remaining assets in `config/`**
  - Review `config/` directory for other assets that should be co-located
  - Identify which programs would benefit from directory module pattern

- [ ] **Co-locate other program assets** (if applicable)
  - Move relevant config files to their program directories
  - Update modules to manage their own assets
  - Remove entries from `xdg.nix`

### Phase 9: Documentation & Cleanup

- [ ] **Update AGENTS.md**
  - Reflect new flat structure in architecture section
  - Update "Add a program" instructions
  - Document `_` prefix convention for draft modules
  - Document upstream alignment decisions

- [ ] **Update README.md**
  - Ensure project README reflects current structure
  - Add examples of both file and directory module patterns

- [ ] **Clean up `config/` directory**
  - Remove empty directories after asset migration
  - Document any remaining non-Nix configs and why they stay

### Phase 10: Validation & Merge

- [ ] **Run full validation**
  - `just fmt` - Format all files
  - `just lint` - Run statix linter
  - `just check` - Run all checks
  - `just build` - Build without applying
  - `just switch` - Apply and verify functionality

- [ ] **Final review**
  - Review all changes for consistency
  - Ensure no regressions in functionality

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

---

## Notes

### Why This Refactoring?

1. **Upstream alignment**: Match official nix-darwin and home-manager patterns
2. **Reduced friction**: Auto-discovery means no import maintenance
3. **Better organization**: Co-located assets are easier to understand
4. **Consistency**: Standard module signatures across all programs
5. **Portability**: Easier to set up on new machines

### Key Files Changed

| File                                 | Purpose                        |
| ------------------------------------ | ------------------------------ |
| `nix/home/programs/default.nix`      | Auto-discovery logic           |
| `nix/home/programs/git/default.nix`  | Example directory module       |
| `nix/home/programs/git/.gitmessage`  | Co-located asset               |
| `nix/home/users/common.nix`          | Simplified imports             |
| `nix/home/programs/xdg.nix`          | Removed migrated symlinks      |
| `docs/UPSTREAM-ANALYSIS.md`          | Gap analysis and recommendations |

### Upstream References

- [home-manager modules/programs/](https://github.com/nix-community/home-manager/tree/master/modules/programs)
- [nix-darwin modules/](https://github.com/nix-darwin/nix-darwin/tree/master/modules)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules)

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

# Inspect upstream repos
gh api repos/nix-community/home-manager/contents/modules/programs --jq '.[].name'
gh api repos/nix-darwin/nix-darwin/contents/modules --jq '.[].name'
```
