# ADR-005: Home-Manager Module Structure Refactoring

## Status

Superseded by [ADR-007](./007-flake-parts-dendritic-migration.md)

## Date

2026-01-20

## Context

The home-manager configuration had evolved organically with a categorized directory structure
under `nix/home/programs/`:

```text
nix/home/programs/        # OLD STRUCTURE (before refactor)
├── dev/
│   ├── bun.nix
│   ├── direnv.nix
│   ├── gh.nix
│   └── git.nix
├── shell/
│   ├── fish.nix
│   ├── nushell.nix
│   └── zsh.nix
├── terminal/
│   ├── bat.nix
│   ├── eza.nix
│   ├── fd.nix
│   ├── fzf.nix
│   ├── ghostty.nix
│   ├── starship.nix
│   └── zoxide.nix
├── session.nix
└── xdg.nix
```

This structure had several issues:

1. **Divergence from upstream conventions**: The official home-manager repository uses a flat
   structure under `modules/programs/` with no subcategories
2. **Arbitrary categorization**: The distinction between "dev", "shell", and "terminal" was often
   unclear (is `fzf` a terminal tool or a dev tool? is `starship` shell or terminal?)
3. **Manual import maintenance**: Every new program required updating the import list in
   `common.nix`
4. **Inconsistent module signatures**: Some modules used `_:` while others used `{ pkgs, ... }:`
5. **No support for complex modules**: Programs needing multiple files or assets had no clear
   pattern to follow
6. **Scattered assets**: Configuration files like `.gitmessage` lived in `config/` separate from
   their associated Nix modules

## Decision

We refactored the home-manager programs structure with four key changes:

### 1. Flatten the Directory Structure

All program modules now live directly under `programs/` at the repository root, without
subcategories or `nix/` prefix:

```text
programs/                # NEW STRUCTURE (after refactor)
├── default.nix          # Auto-discovery module
├── 1password.nix        # 1Password CLI + shell plugins
├── bat.nix
├── bun.nix
├── direnv.nix
├── eza.nix
├── fd.nix
├── fish/                # Directory for modular config
│   ├── default.nix
│   ├── abbreviations.nix
│   ├── aliases.nix
│   └── functions.nix
├── fzf.nix
├── gh.nix
├── git/                 # Directory for complex modules
│   ├── default.nix
│   └── .gitmessage
├── ghostty.nix
├── nushell.nix
├── session.nix
├── ssh.nix              # Declarative SSH config
├── starship.nix
├── xdg.nix
├── zed/                 # Co-located config files
│   ├── default.nix
│   ├── settings.json
│   ├── keymap.json
│   └── tasks.json
├── zoxide.nix
└── zsh.nix
```

### 2. Implement Auto-Discovery

A new `programs/default.nix` automatically discovers and imports all modules:

```nix
{ lib, ... }:
let
  # Get all entries in this directory
  entries = builtins.readDir ./.;

  # Filter to only .nix files and directories (excluding default.nix and _ prefixed)
  isModule = name: type:
    let
      isNixFile = type == "regular" && lib.hasSuffix ".nix" name;
      isDirectory = type == "directory";
      isDefault = name == "default.nix";
      isDraft = lib.hasPrefix "_" name;
    in
    (isNixFile || isDirectory) && !isDefault && !isDraft;

  moduleEntries = lib.filterAttrs isModule entries;

  # Convert to import paths
  toImport = name: type:
    if type == "directory"
    then ./${name}
    else ./${name};
in
{
  imports = lib.mapAttrsToList toImport moduleEntries;
}
```

**Conventions:**

- Files ending in `.nix` are auto-imported
- Directories with `default.nix` are auto-imported
- Files/directories starting with `_` are excluded (draft convention)
- `default.nix` itself is excluded from discovery

### 3. Support Both File and Directory Patterns

- **Simple programs**: Single file (e.g., `bat.nix`)
- **Complex programs**: Directory with `default.nix` (e.g., `git/default.nix`)

The directory pattern is used when a program needs:

- Multiple configuration files
- Co-located assets (templates, scripts, etc.)
- Sub-modules for organization

### 4. Standardize Module Signatures

All modules now use proper NixOS module conventions:

```nix
# Module header comment explaining purpose
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkDefault;
in
{
  programs.example = {
    enable = mkDefault true;
    # ... configuration
  };
}
```

Key conventions:

- Full module signature: `{ config, lib, pkgs, ... }:`
- Use `inherit (lib) mkDefault;` for cleaner code
- Apply `mkDefault` to values that users might want to override
- Add descriptive header comments
- Use section comments (`# ── Section ──`) for organization

### 5. Co-locate Assets with Modules

Configuration assets live alongside their modules:

```text
programs/git/
├── default.nix      # Git configuration module
└── .gitmessage      # Commit message template
```

The module manages its own assets via `xdg.configFile`:

```nix
# In git/default.nix
xdg.configFile."git/gitmessage".source = ./.gitmessage;
```

## Consequences

### Positive

- **Follows upstream conventions**: Matches official home-manager structure
- **Zero-maintenance imports**: New programs are automatically discovered
- **Clear module patterns**: Simple (file) vs. complex (directory) is obvious
- **Self-contained modules**: Assets live with their configuration
- **Consistent code style**: All modules follow the same conventions
- **Easy to add programs**: Just create a `.nix` file, no import updates needed
- **Draft support**: Prefix with `_` to exclude work-in-progress modules

### Negative

- **Less categorization**: Can't browse programs by category (dev/shell/terminal)
- **Flat namespace**: Many files in one directory (mitigated by alphabetical ordering)
- **Migration effort**: One-time cost to move existing modules (completed)
- **Learning curve**: Team members need to learn the new conventions

### Neutral

- Module count remains the same, just reorganized
- No functional changes to the actual configurations
- IDE navigation works the same (file search, go-to-definition)

## Alternatives Considered

### 1. Keep Categorized Structure

Maintain `dev/`, `shell/`, `terminal/` subdirectories.

**Rejected because**: Upstream doesn't use this pattern, categories were arbitrary and often
debatable, and it added cognitive overhead when deciding where new programs belong.

### 2. Use Tags/Metadata Instead of Directories

Add metadata to each module indicating its category, queryable but not directory-based.

**Rejected because**: Adds complexity, Nix doesn't have a standard way to do this, and the benefit
of categorization didn't justify the implementation cost.

### 3. Keep Manual Imports

Continue maintaining explicit import lists in `common.nix`.

**Rejected because**: Error-prone, easy to forget adding new modules, and unnecessary boilerplate
when auto-discovery is straightforward to implement.

### 4. Use a Single Monolithic File

Put all program configurations in one file.

**Rejected because**: Already rejected in [ADR-003](./003-nix-lsp-maintainability-tradeoff.md).
Maintainability is more important than LSP completeness.

### 5. Symlink Assets from config/

Keep assets in `config/` and symlink them.

**Rejected because**: Separates logically related files, makes it harder to understand what a module
does, and complicates module portability.

## Migration Steps

These migration steps have been completed. For reference:

1. **Flattened directory structure**: Removed `nix/` prefix entirely
   - `nix/home/programs/` → `programs/`
   - `nix/darwin/modules/` → `modules/`
   - `nix/darwin/configuration.nix` → `darwin.nix`
   - `nix/home/users/common.nix` → `home.nix`

2. **Auto-discovery**: Both `programs/default.nix` and `modules/default.nix` use
   shared `lib/auto-discovery.nix`

3. **Directory modules created**:
   - `programs/git/` - with `.gitmessage`
   - `programs/fish/` - with abbreviations, aliases, functions
   - `programs/zed/` - with settings.json, keymap.json, tasks.json

4. **Test the configuration**:

   ```bash
   just check   # Format, lint, deadcode
   just build   # Build without applying
   just switch  # Apply configuration
   ```

## Future Considerations

- **More co-located assets**: As other programs need templates or scripts, move them into module
  directories (fish/, zed/, git/ patterns are now established)
- **Shared utilities**: Created `lib/auto-discovery.nix` for shared functions
- **Documentation generation**: Auto-discovery enables potential tooling to generate documentation
  from module structure
- **Testing patterns**: Could add `_test.nix` files alongside modules for testing configurations

## References

- [home-manager modules/programs/](https://github.com/nix-community/home-manager/tree/master/modules/programs)
- [nix-darwin modules/](https://github.com/nix-darwin/nix-darwin/tree/master/modules)
- [NixOS module system documentation](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [ADR-003: Nix LSP Maintainability Trade-off](./003-nix-lsp-maintainability-tradeoff.md)
- [ADR-001: Multi-Machine Nix Configuration](./001-multi-machine-nix-configuration.md)