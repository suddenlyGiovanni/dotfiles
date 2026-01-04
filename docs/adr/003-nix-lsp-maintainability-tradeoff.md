# ADR-003: Nix LSP Maintainability Trade-off

## Status

Accepted

## Date

2025-01

## Context

When working with nix-darwin and home-manager configurations, having proper IDE support (autocompletion, type checking, go-to-definition) significantly improves the developer experience. The Nix ecosystem has several LSP implementations:

- **nil** - A Nix LSP focused on language features
- **nixd** - A Nix LSP with support for evaluating flakes and providing option completions

During the modular refactoring of our nix-darwin configuration (see [ADR-001](./001-multi-machine-nix-configuration.md)), we encountered a significant limitation: **LSP autocompletion for nix-darwin and home-manager module options did not work reliably in our modular file structure**.

### The Problem

In files like `nix/darwin/modules/system-defaults.nix`, we wanted:
- Autocompletion for `system.defaults.*` options
- Type information for valid values
- Documentation on hover

However, the LSP couldn't determine the evaluation context for these standalone module files. The LSP saw them as isolated Nix expressions, not as modules being evaluated within a nix-darwin configuration.

### Experiments Attempted

1. **Proper module signatures**: Changed `_:` to `{ config, lib, pkgs, ... }:` in all modules
   - Helped LSP understand some bindings but didn't provide darwin/home-manager specific options
   - Triggered statix/deadnix warnings for unused parameters

2. **`.nixd.json` configuration**: Created a nixd config pointing to flake darwin options:
   ```json
   {
     "nixpkgs": { "expr": "import <nixpkgs> {}" },
     "options": {
       "darwin": { "expr": "(builtins.getFlake \"path:./nix/darwin\").darwinConfigurations.personal.options" }
     }
   }
   ```
   - Required expensive flake evaluation on every LSP query
   - Inconsistent results, sometimes worked, often timed out
   - Heavy CPU/memory usage during editing

3. **Inlining modules into `configuration.nix`**: Merged all module contents into a single file
   - Improved autocompletion significantly
   - Made the file extremely long and hard to navigate
   - Lost the benefits of modular organization

4. **Full inline into `flake.nix`**: Put entire darwin configuration directly in flake.nix
   - Best LSP results—full autocompletion and type info
   - Completely unmaintainable for a multi-machine setup
   - Thousands of lines in a single file
   - Impossible to share configuration between hosts

## Decision

We chose to **prioritize maintainability over LSP completeness**.

The modular file structure is retained despite the LSP limitations:

```
nix/
├── darwin/
│   ├── flake.nix              # Entry point
│   ├── configuration.nix      # Shared darwin config
│   ├── modules/               # System modules (modular, maintainable)
│   │   ├── homebrew.nix
│   │   ├── security.nix
│   │   └── system-defaults.nix
│   └── hosts/
│       ├── personal.nix
│       └── work.nix
└── home/
    ├── programs/              # Program configs (modular, maintainable)
    │   ├── shell/
    │   ├── terminal/
    │   └── dev/
    └── users/
```

### Mitigations for Limited LSP

To work effectively despite incomplete autocompletion:

1. **Use documentation**: Keep browser tabs open for:
   - [nix-darwin options search](https://daiderd.com/nix-darwin/manual/index.html)
   - [home-manager options search](https://nix-community.github.io/home-manager/options.html)
   - [NixOS options search](https://search.nixos.org/options) (many overlap)

2. **Small, focused modules**: Each module handles one concern, making it easier to understand without IDE hints

3. **Consistent module signatures**: Use `{ config, lib, pkgs, ... }:` even if parameters are unused, for documentation purposes

4. **Inline comments**: Document non-obvious option values and their effects

5. **Validation before committing**: Always run `darwin-rebuild build` to catch type errors that LSP missed

## Consequences

### Positive

- **Maintainable codebase**: Files stay small and focused
- **Multi-machine support**: Easy to add hosts with shared configuration
- **Clear separation of concerns**: System vs. user, host vs. common
- **Version control friendly**: Small files, meaningful diffs
- **Easy onboarding**: New users can understand the structure
- **No heavy flake evaluation during editing**: Editor stays responsive

### Negative

- **Limited autocompletion**: Must reference documentation for option names and types
- **No inline type errors**: Type mismatches only caught at build time
- **Manual option discovery**: Can't browse available options via autocomplete
- **Higher learning curve for Nix beginners**: Less IDE hand-holding

### Neutral

- LSP still works for Nix language features (syntax, basic completion, formatting)
- The situation may improve as Nix LSP tooling matures
- Other Nix projects with simpler structures may have better LSP support

## Alternatives Considered

### 1. Accept inlined configuration

Put all configuration in one file for best LSP support.

**Rejected because**: A 2000+ line `flake.nix` is unmaintainable. The cognitive overhead of navigating one massive file exceeds the benefit of autocompletion.

### 2. Hybrid approach

Inline the most frequently edited modules, keep rarely-changed modules separate.

**Rejected because**: Creates an inconsistent codebase where some settings are in one place and others elsewhere. Also unclear where the line should be drawn.

### 3. Wait for better tooling

Don't use LSP at all, wait for improvements.

**Rejected because**: We still get value from LSP for Nix syntax, formatting, and some completions. Partial support is better than none.

### 4. Custom type stubs/annotations

Create Nix expressions that define types for the LSP to understand.

**Rejected because**: Significant ongoing maintenance burden to keep stubs in sync with upstream options. Not a sustainable solution for a personal dotfiles repo.

### 5. Use a flake-parts or similar framework

Adopt a framework that might structure things in a more LSP-friendly way.

**Considered but deferred**: May revisit in the future. Current structure is well-understood and works. Adding a framework adds complexity and learning curve.

## Future Considerations

- **Monitor nixd development**: The nixd project is actively improving; future versions may handle modular configurations better
- **Revisit `.nixd.json`**: As flake evaluation becomes faster or nixd adds caching, this approach may become viable
- **Consider precomputed options**: Could potentially generate a JSON file of available options for reference, though not connected to LSP
- **Flake-parts evaluation**: If migrating to flake-parts, reassess LSP behavior in that structure

## Lessons Learned

1. **IDE support is not guaranteed**: Unlike mainstream languages, Nix tooling is still maturing
2. **Maintainability compounds**: Time saved by LSP is dwarfed by time lost in unmaintainable code
3. **Documentation access is essential**: Good bookmark organization and docs familiarity partially compensates for missing autocomplete
4. **Build-time validation is crucial**: `darwin-rebuild build` catches errors that LSP misses

## References

- [nixd GitHub repository](https://github.com/nix-community/nixd)
- [nil GitHub repository](https://github.com/oxalica/nil)
- [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)
- [ADR-001: Multi-Machine Nix Configuration](./001-multi-machine-nix-configuration.md)