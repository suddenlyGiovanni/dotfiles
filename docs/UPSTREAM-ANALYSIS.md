# Upstream Pattern Analysis

> Comparing nix-darwin and home-manager conventions with this dotfiles repository

This document analyzes the coding patterns, conventions, and organizational structures used in the
upstream [nix-darwin](https://github.com/nix-darwin/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager) repositories, and compares them to the
patterns used in this dotfiles configuration.

The goal is to identify gaps and opportunities to align with upstream best practices for improved
maintainability, consistency, and compatibility.

---

## Table of Contents

- [Upstream Patterns](#upstream-patterns)
  - [Module Signature & Structure](#module-signature--structure)
  - [File Organization](#file-organization)
  - [Code Style](#code-style)
- [Current State Analysis](#current-state-analysis)
  - [What's Already Aligned](#whats-already-aligned)
  - [Gaps to Address](#gaps-to-address)
- [Recommendations](#recommendations)
  - [High Priority (Correctness)](#high-priority-correctness)
  - [Medium Priority (Consistency)](#medium-priority-consistency)
  - [Lower Priority (Polish)](#lower-priority-polish)
  - [Keep As-Is (Don't Change)](#keep-as-is-dont-change)

---

## Upstream Patterns

### Module Signature & Structure

#### 1. Standard Module Signature

All upstream modules use a consistent signature:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
```

#### 2. Let Block with Multi-line Inherit

Functions are imported using multi-line `inherit` with trailing semicolon:

```nix
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.example;
in
```

#### 3. The `cfg` Pattern

Modules define a `cfg` binding to access their own configuration:

```nix
let
  cfg = config.programs.bat;
in
{
  # Later in the module:
  config = mkIf cfg.enable {
    # ...
  };
}
```

#### 4. Separate `options` and `config` Blocks

Upstream modules separate option definitions from configuration:

```nix
{
  options.programs.example = {
    enable = mkEnableOption "example program";
    package = lib.mkPackageOption pkgs "example" { };
    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Configuration options for example.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    # ...
  };
}
```

#### 5. Standard Option Helpers

| Helper                  | Purpose                              | Example                              |
| ----------------------- | ------------------------------------ | ------------------------------------ |
| `mkEnableOption`        | Boolean enable flag with description | `mkEnableOption "bat"`               |
| `lib.mkPackageOption`   | Package selection with defaults      | `lib.mkPackageOption pkgs "bat" { }` |
| `mkOption`              | Custom options with type/description | See above                            |
| `literalExpression`     | Example values in docs               | `example = literalExpression "..."` |
| `mkDefault`             | Overridable default values           | `theme = mkDefault "ansi";`          |

#### 6. Maintainer Metadata

Upstream modules include maintainer information:

```nix
{
  meta.maintainers = with lib.maintainers; [ khaneliman rycee ];
}
```

### File Organization

#### Flat Module Structure

Upstream uses a flat structure under `modules/programs/`:

```text
modules/programs/
├── bat.nix
├── eza.nix
├── fzf.nix
├── git.nix
└── zsh/           # Directory for complex modules
    ├── default.nix
    ├── deprecated.nix
    ├── history.nix
    ├── lib.nix
    └── plugins/
```

#### Complex Module Directories

When a program needs multiple files, it uses a directory:

| File             | Purpose                              |
| ---------------- | ------------------------------------ |
| `default.nix`    | Main module entry point              |
| `deprecated.nix` | Deprecation warnings and migrations  |
| `lib.nix`        | Shared utilities for the module      |
| `history.nix`    | Sub-feature module                   |
| `plugins/`       | Sub-modules for plugin configuration |

#### Explicit Module List

Upstream uses explicit module lists rather than auto-discovery:

```nix
# modules/modules.nix (home-manager)
let
  modules = [
    ./programs/bat.nix
    ./programs/eza.nix
    ./programs/fzf.nix
    ./programs/git.nix
    ./programs/zsh
    # ... many more
  ];
in
```

```nix
# modules/module-list.nix (nix-darwin)
[
  ./programs/bash
  ./programs/direnv.nix
  ./programs/fish.nix
  ./programs/zsh
  ./homebrew.nix
  # ...
]
```

### Code Style

#### Formatting

- Uses nixfmt or alejandra for consistent formatting
- Multi-line expressions are properly indented
- Trailing commas in lists and attribute sets

#### Comments

- Minimal inline comments
- Comments on their own lines, not after values
- Section comments are rare in upstream

#### Condition Patterns

```nix
# Conditional configuration
config = mkIf cfg.enable {
  # Only applied when enabled
};

# Conditional package inclusion
home.packages = mkIf cfg.enable [ cfg.package ];

# Optional string
optionalString (cfg.theme != null) "--theme=${cfg.theme}"
```

---

## Current State Analysis

### What's Already Aligned

| Pattern                         | Status | Notes                                          |
| ------------------------------- | ------ | ---------------------------------------------- |
| Module signature                | ✅      | Using `{ config, lib, pkgs, ... }:`            |
| `inherit (lib)` pattern         | ✅      | Using instead of `with lib;`                   |
| Flat directory structure        | ✅      | Programs in `nix/home/programs/`               |
| `mkDefault` for overridable     | ✅      | Applied to values users might customize        |
| Directory modules               | ✅      | `git/default.nix` pattern implemented          |
| Co-located assets               | ✅      | `.gitmessage` with git module                  |
| Header comments                 | ✅      | Links to upstream module documentation         |
| Section comments (`── ...`)     | ✅      | Aids readability (personal style)              |
| Auto-discovery                  | ✅      | Convenient for personal dotfiles               |

### Gaps to Address

#### 1. Duplicate Packages in `common.nix`

**Issue**: Several packages are listed twice in the packages list.

```nix
# Current (problematic)
packages = with pkgs; [
  _1password-cli
  alejandra
  # ... many packages ...
  _1password-cli    # DUPLICATE
  alejandra         # DUPLICATE
  nixd              # DUPLICATE
  # ...
];
```

**Fix**: Remove duplicate entries.

#### 2. Duplicate direnv Configuration

**Issue**: `direnv` is configured in both `common.nix` and `direnv.nix`.

```nix
# common.nix
programs.direnv = {
  enable = true;
  enableZshIntegration = mkDefault true;
  nix-direnv.enable = mkDefault true;
};

# direnv.nix - also configures direnv
```

**Fix**: Remove from `common.nix`, keep only in `direnv.nix`.

#### 3. Inconsistent `let` Block Formatting

**Issue**: Single-line inherit vs multi-line.

```nix
# Current
let
  inherit (lib) mkDefault;
in

# Upstream style
let
  inherit (lib)
    mkDefault
    mkIf
    ;
in
```

**Fix**: Use multi-line format for consistency with upstream.

#### 4. Missing `cfg` Pattern

**Issue**: Modules don't use the `cfg = config.programs.X` pattern.

```nix
# Current
programs.bat = {
  enable = true;
  config.theme = mkDefault "ansi";
};

# With cfg pattern (more idiomatic for accessing own config)
let
  cfg = config.programs.bat;
in
{
  programs.bat = {
    enable = true;
    config.theme = mkDefault "ansi";
  };

  # Can reference cfg.package, cfg.config, etc. elsewhere
}
```

**Note**: For simple consumer modules (not defining new options), this is less important.

#### 5. Large Monolithic `system-defaults.nix`

**Issue**: All macOS defaults in one 150+ line file.

```text
# Current
nix/darwin/modules/
├── homebrew.nix
├── security.nix
└── system-defaults.nix  # Everything in one file

# More modular (upstream style)
nix/darwin/modules/
├── homebrew.nix
├── security.nix
└── system-defaults/
    ├── default.nix      # Imports all
    ├── dock.nix
    ├── finder.nix
    ├── trackpad.nix
    └── nsglobaldomain.nix
```

**Trade-off**: More files to manage vs easier to find specific settings.

#### 6. `userConfig` vs Standard Patterns

**Issue**: Custom `userConfig` passed through `specialArgs`.

```nix
# Current
specialArgs = {
  inherit (hostConfig) userConfig;
};

# In modules
{ userConfig, ... }:
```

**Alternative**: Use standard `config.home.username`, `config.home.homeDirectory`.

**Note**: Current approach works fine, just non-standard.

---

## Recommendations

### High Priority (Correctness)

#### H1: Remove Duplicate Packages

**File**: `nix/home/users/common.nix`

Remove duplicate entries from `home.packages`. The following appear twice:
- `_1password-cli`
- `alejandra`
- `nixd`
- `awscli2`
- `container`
- `dive`
- `docker-buildx`
- `docker-slim`
- `lazydocker`
- `nodejs_24`
- `pnpm`
- `biome`
- `uv`
- `rustup`
- `cocoapods`
- `glow`
- `httpie`
- `jq`
- `just`
- `shellcheck`
- `shfmt`

#### H2: Consolidate direnv Configuration

**Files**: `nix/home/users/common.nix`, `nix/home/programs/direnv.nix`

Remove `programs.direnv` block from `common.nix`. Keep configuration only in `direnv.nix`.

### Medium Priority (Consistency)

#### M1: Standardize `let` Block Formatting

Update all modules to use multi-line inherit with trailing semicolon:

```nix
# Before
let
  inherit (lib) mkDefault;
in

# After
let
  inherit (lib)
    mkDefault
    ;
in
```

#### M2: Consider Splitting `system-defaults.nix`

Split into focused files:

| File                 | Contents                            |
| -------------------- | ----------------------------------- |
| `dock.nix`           | Dock preferences                    |
| `finder.nix`         | Finder preferences                  |
| `trackpad.nix`       | Trackpad settings                   |
| `nsglobaldomain.nix` | NSGlobalDomain settings             |
| `window-manager.nix` | WindowManager settings              |
| `login-window.nix`   | Login window settings               |
| `default.nix`        | Imports all above + ActivityMonitor |

#### M3: Add `cfg` Pattern Where Beneficial

For modules that reference their own config multiple times, add:

```nix
let
  cfg = config.programs.git;
in
```

### Lower Priority (Polish)

#### L1: Consistent Section Comments

Decide whether to keep `# ── Section ──` style comments:
- **Keep**: Aids navigation in larger files
- **Remove**: Not used upstream, adds visual noise

Recommendation: Keep for files >50 lines, remove for smaller files.

#### L2: Consider Explicit Module List

Replace auto-discovery with explicit list for more control:

```nix
# nix/home/programs/default.nix
{
  imports = [
    ./bat.nix
    ./bun.nix
    ./direnv.nix
    # ... explicitly list all
  ];
}
```

**Trade-off**: More maintenance vs explicit control and alphabetization.

Recommendation: Keep auto-discovery for personal dotfiles (convenience > explicitness).

#### L3: Standardize `userConfig` Approach

Document the `userConfig` pattern in ADR or keep using standard home-manager patterns.

Current approach is fine but should be documented.

### Keep As-Is (Don't Change)

| Pattern                     | Reason                                        |
| --------------------------- | --------------------------------------------- |
| Direct `enable = true`      | Fine for consumer modules (not defining opts) |
| Auto-discovery              | Convenient for personal use                   |
| Header comments with links  | Helpful documentation                         |
| Co-located assets           | Already following best practice               |
| `mkDefault` usage           | Correct and idiomatic                         |
| Flat structure              | Matches upstream                              |

---

## Implementation Checklist

```markdown
## Immediate Fixes
- [x] Remove duplicate packages in common.nix ✓
- [x] Remove direnv config from common.nix (keep in direnv.nix) ✓

## Style Improvements
- [x] Update let blocks to multi-line inherit format ✓
- [ ] Add cfg pattern to complex modules (git, zsh) - SKIPPED (not needed for consumer modules)

## Structural Improvements
- [x] Split system-defaults.nix into focused modules ✓
- [ ] Document userConfig pattern in ADR

## Validation
- [x] Run `just fmt` after changes ✓
- [x] Run `just lint` to check for issues ✓
- [x] Run `just build` to verify configuration ✓
- [ ] Run `just switch` to apply and test
```

---

## References

- [home-manager modules/programs/](https://github.com/nix-community/home-manager/tree/master/modules/programs)
- [nix-darwin modules/](https://github.com/nix-darwin/nix-darwin/tree/master/modules)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [ADR-005: Home-Manager Module Structure](./adr/005-home-manager-module-structure.md)