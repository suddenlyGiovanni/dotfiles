# ADR-007: Flake-Parts and Dendritic Pattern Migration

## Status

Accepted

## Date

2026-02-22

## Context

The dotfiles repository uses a traditional Nix flake with a hand-rolled `mkDarwinConfig` helper
function, `specialArgs`/`extraSpecialArgs` for threading shared values, and separate directory trees
for nix-darwin modules (`modules/`) and home-manager modules (`programs/`). While this architecture
(established in ADR-001 and refined in ADR-005) has served well, several limitations have emerged:

1. **Mixed file types**: Files in `modules/` are nix-darwin modules, files in `programs/` are
   home-manager modules, and files in `hosts/` are plain attrsets. There is no uniform answer to
   "what type is this file?"

2. **`specialArgs` threading**: Shared values (`hostConfig`, `userConfig`, `hostname`) are passed
   through `specialArgs` and `extraSpecialArgs` in `flake.nix`, then destructured by individual
   modules. Adding a new shared value requires editing the `mkDarwinConfig` function and every
   module that needs it.

3. **No cross-cutting features**: Fish shell requires both a darwin-level config
   (`programs.fish.enable = true` in `darwin.nix`) and a home-manager-level config
   (`programs/fish/default.nix`). These live in separate files in separate directories, making the
   "fish" feature scattered across the codebase.

4. **Manual host wiring**: The `mkDarwinConfig` function manually threads together nix-darwin,
   home-manager, nix-homebrew, and mac-app-util with explicit module lists. Adding a new integration
   requires modifying this central function.

5. **Host data as plain attrsets**: `hosts/personal.nix` and `hosts/work.nix` return plain Nix
   attrsets without type checking. Typos in field names (e.g., `hostName` vs `hostname`) cause
   silent failures rather than type errors.

## Decision

We will migrate to [flake-parts](https://flake.parts/) as the top-level module system and adopt the
[dendritic pattern](https://github.com/mightyiam/dendritic) for organizing configuration modules.

### What is flake-parts?

Flake-parts is a minimal framework that wraps the Nixpkgs module system around Nix flake outputs.
Instead of hand-assembling the `outputs` attrset, you define flake-parts modules that declare and
set options, and flake-parts evaluates them into the standard flake output schema. It provides:

- `mkFlake` -- entry point replacing the manual `outputs` function
- `systems` option -- replaces `forAllSystems` boilerplate
- `perSystem` -- per-architecture outputs (formatter, devShells, packages)
- `flake.modules.<class>.<name>` -- storage for lower-level configuration modules (optional)

### What is the dendritic pattern?

The dendritic pattern (by @mightyiam) is a usage pattern for the Nixpkgs module system where:

1. **Every non-entry-point `.nix` file is a module of the top-level configuration** (in our case, a
   flake-parts module).

2. **Each file implements a single feature** across all configuration classes that feature applies to
   (nix-darwin, home-manager, etc.).

3. **File paths name features**, not configuration classes. A file is named `fish.nix`, not
   `programs/fish.nix` or `modules/fish.nix`.

4. **Shared values are top-level options**, not `specialArgs`. Any module can read from and write to
   the shared `config` object.

### Key technical concepts

#### `deferredModule` type

`lib.types.deferredModule` is a Nixpkgs option type for storing modules that have not yet been
evaluated. Its critical property is **merge semantics**: when multiple modules write to the same
`deferredModule` option, their contributions are automatically merged, just like modules merge in
NixOS.

flake-parts uses this type for `flake.modules.<class>.<name>`, which stores nix-darwin,
home-manager, and other modules as deferred values. They are only evaluated when the host assembly
module calls `darwinSystem` or similar.

#### Closure technique for value bridging

A flake-parts module's outer function receives the flake-parts `config` (with `dotfiles.user.*`,
etc.). The inner `deferredModule` receives the lower-level `config` (nix-darwin or home-manager).
Values are bridged via closure:

```nix
# Outer: flake-parts module
{ config, ... }: let
  username = config.dotfiles.user.username;  # flake-parts config
in {
  flake.modules.darwin.core = { pkgs, ... }: {  # nix-darwin config
    users.users.${username}.shell = pkgs.fish;
  };
}
```

#### Cross-cutting feature modules

A single file can write to multiple configuration classes:

```nix
{ config, ... }: {
  # darwin-level: enable fish as valid login shell
  flake.modules.darwin.fish = _: {
    programs.fish.enable = true;
  };

  # home-manager-level: configure fish for the user
  flake.modules.homeManager.fish = { pkgs, ... }: {
    programs.fish = {
      enable = true;
      package = pkgs.fish;
      # ...
    };
  };
}
```

#### `import-tree` for auto-discovery

[import-tree](https://github.com/vic/import-tree) recursively imports all `.nix` files from a
directory as flake-parts modules. Paths containing `/_` are excluded. This replaces our custom
`lib/auto-discovery.nix`.

### Migration strategy

The migration is **incremental** across 10 phases, each producing a buildable configuration. A
temporary "legacy bridge" module reconstructs the old `hostConfig`/`userConfig` shapes from new
top-level options, allowing existing modules to work unchanged during transition. Modules are
migrated one-by-one or in small batches, with the old directories shrinking over time until they
can be deleted.

The phases are:

0. Write this ADR (documentation only)
1. Add `flake-parts` and `import-tree` inputs (no behavioral change)
2. Wrap outputs in `mkFlake` + create legacy bridge
3. Define top-level options + migrate host data
4. Enable `flake.modules` + `import-tree` scaffold
5. Batch-migrate pure darwin modules (12 modules, no specialArgs deps)
6. Batch-migrate pure HM modules (~26 modules, no specialArgs deps)
7. Eliminate `userConfig` specialArgs (fish, zsh, zed, darwin-core, home-core)
8. Eliminate `hostConfig` specialArgs (dock, homebrew)
9. Eliminate `hostname` specialArgs (1password)
10. Replace legacy bridge with clean host assembly + final cleanup

### Target directory structure

```text
flake.nix                            # ~20 lines: inputs + mkFlake + import-tree
modules/
  options.nix                        # dotfiles.user.* and dotfiles.hosts.* declarations
  hosts.nix                          # concrete values for personal + work
  features/
    host-assembly.nix                # builds darwinConfigurations from options + modules
    darwin-core.nix                  # system packages, users, nix settings
    home-core.nix                    # home.packages, stateVersion
    activity-monitor.nix             # darwin-only feature
    dock.nix                         # darwin-only (shared settings)
    homebrew.nix                     # darwin-only (shared casks)
    security.nix                     # darwin-only feature
    ...                              # (more darwin-only features)
    fish/                            # CROSS-CUTTING (darwin + HM in one file)
      default.nix
      abbreviations.nix
      aliases.nix
      completions.nix
      functions.nix
    git/                             # HM-only + co-located .gitmessage
    1password/                       # HM-only + co-located agent.toml
    zed/                             # HM-only + co-located JSON configs
    bat.nix, bun.nix, ...            # HM-only feature modules
```

## Consequences

### Positive

- **Uniform file types**: Every `.nix` file under `modules/` is a flake-parts module. No
  ambiguity about what type a file contains.
- **No `specialArgs`/`extraSpecialArgs`**: Shared values are top-level options, readable by any
  module without explicit threading. Adding a new shared value is a one-line option declaration.
- **Cross-cutting features**: A feature like fish that touches both system and user config lives in
  a single file, making it easy to understand and modify holistically.
- **Typed host configuration**: Host data is validated by the Nixpkgs module system with proper
  types. Typos produce clear errors instead of silent failures.
- **Zero-maintenance imports**: `import-tree` auto-discovers modules. Adding a new feature =
  dropping a file.
- **Incremental adoption**: Each phase produces a buildable config. The migration can be paused and
  resumed at any phase boundary.

### Negative

- **Wrapper boilerplate**: Every module gains ~2 lines of `deferredModule` wrapping
  (`_: { flake.modules.homeManager.foo = ...; }`). This is the cost of uniformity.
- **Learning curve**: Contributors must understand the dendritic pattern, `deferredModule` type, and
  the closure technique for bridging config levels.
- **Two `config` scopes**: In modules that use the closure technique, there are two `config` objects
  (flake-parts outer, lower-level inner). This requires care to avoid confusion.
- **New dependencies**: `flake-parts` and `import-tree` are added as flake inputs.

### Neutral

- Same number of output attributes (`darwinConfigurations`, `formatter`, `devShells`)
- Same module count, reorganized
- `flake-parts` is already a transitive dependency (via `mac-app-util`)
- Supersedes ADR-005 (Home-Manager Module Structure) since the flat `programs/` directory is
  replaced by `modules/features/`

## Alternatives Considered

### 1. Plain flake-parts without dendritic

Use flake-parts for `mkFlake`, `perSystem`, etc., but keep separate `modules/` and `programs/`
directories with their current file types.

**Rejected because**: This captures only half the benefit. `specialArgs` would still be needed, and
cross-cutting features would still be scattered across directories. The dendritic pattern is what
eliminates these structural issues.

### 2. Big-bang rewrite

Rewrite the entire configuration in one pass to the target architecture.

**Rejected because**: High risk of regressions with no intermediate buildable states. The
incremental approach via the legacy bridge is safer and allows validation at each step.

### 3. `flake-file` (vic/flake-file)

Use `flake-file` to auto-generate `flake.nix` entirely, further minimizing the entry point.

**Rejected because**: Adds another dependency and obscures the entry point. For a personal dotfiles
repo with 2 hosts, an explicit ~20-line `flake.nix` is clearer. It can be adopted later if desired.

### 4. Custom `lib.evalModules` without flake-parts

Use the Nixpkgs module system directly via `lib.evalModules` for the top-level configuration.

**Rejected because**: Flake-parts already provides well-tested integration with the flake schema,
`systems` handling, and the `flake.modules` option. Reimplementing this would be unnecessary work.

## References

- [flake-parts documentation](https://flake.parts/)
- [flake-parts `flake.modules` option](https://flake.parts/options/flake-parts-modules.html)
- [The Dendritic Pattern](https://github.com/mightyiam/dendritic)
- [Dendritic annotated example](https://github.com/mightyiam/dendritic/tree/master/example)
- [Doc-Steve: Dendritic design with flake-parts](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [vic/import-tree](https://github.com/vic/import-tree)
- [vic/dendrix: On the benefits of the dendritic pattern](https://github.com/vic/dendrix)
- [`deferredModule` type in Nixpkgs](https://nixos.org/manual/nixpkgs/stable/#sec-option-types-submodule)
- [ADR-001: Multi-Machine Nix Configuration](./001-multi-machine-nix-configuration.md)
- [ADR-005: Home-Manager Module Structure](./005-home-manager-module-structure.md)
