# ADR-001: Multi-Machine Nix Configuration

## Status

Accepted

## Date

2025-01

## Context

The dotfiles repository was originally designed for a single macOS machine (personal MacBook Air)
using nix-darwin and home-manager. With the upcoming need to set up a work MacBook while retaining
the personal machine, we needed a way to:

1. Share common configuration between machines (system preferences, packages, shell configs)
2. Allow machine-specific settings (hostname, architecture, per-host apps)
3. Allow user-specific settings (git email, SSH signing keys)
4. Keep the configuration maintainable and DRY (Don't Repeat Yourself)
5. Enable safe, incremental changes without breaking the working setup

The original configuration had everything in a single `flake.nix` with an inline `configuration`
function and hardcoded values like username (`suddenlygiovanni`) and home directory
(`/Users/suddenlygiovanni`).

## Decision

We restructured the nix-darwin configuration into a modular, multi-machine architecture:

```
dotfiles/
├── nix/
│   ├── darwin/                      # nix-darwin system configuration
│   │   ├── flake.nix                # Entry point with mkDarwinConfig helper
│   │   ├── configuration.nix        # Shared darwin system settings
│   │   ├── modules/                 # System-level modules
│   │   │   ├── homebrew.nix         # Shared Homebrew configuration
│   │   │   ├── security.nix         # Security settings
│   │   │   └── system-defaults.nix  # macOS system preferences
│   │   └── hosts/                   # Machine-specific configs
│   │       ├── personal.nix         # Personal MacBook Air
│   │       └── work.nix             # Work MacBook
│   └── home/                        # home-manager user environment
│       ├── programs/                # Program configurations by category
│       │   ├── shell/               # zsh, fish, nushell
│       │   ├── terminal/            # starship, bat, eza, fd, etc.
│       │   ├── dev/                 # git, gh
│       │   └── xdg.nix              # XDG directories & config symlinks
│       └── users/                   # User-specific configs
│           ├── common.nix           # Shared packages and programs
│           ├── personal.nix         # Personal git identity
│           └── work.nix             # Work git identity
└── config/                          # Non-Nix configs symlinked via xdg.nix
    ├── zed/                         # Zed editor settings
    └── git/                         # Git commit templates
```

### Key Design Decisions

1. **Host configurations as data, not modules**: Host files (`nix/darwin/hosts/*.nix`) are simple
   attribute sets containing machine-specific values, not NixOS modules. This keeps them simple and
   declarative.

2. **`mkDarwinConfig` helper function**: A single function in `flake.nix` that takes a host
   configuration and produces a complete darwin system. This ensures consistency and reduces
   duplication.

3. **User configuration passed via `specialArgs`**: The `userConfig` attribute set is passed through
   `specialArgs` to all modules, making user-specific values available everywhere without
   hardcoding.

4. **Separation of darwin (system) and home (user)**: System-level configs live under `nix/darwin/`,
   user-level configs under `nix/home/`. This mirrors the nix-darwin and home-manager separation.

5. **Separation of users from hosts**: User configurations (`nix/home/users/*.nix`) are separate
   from host configurations, allowing the same user config to be reused across machines.

6. **Common base with overrides**: `nix/home/users/common.nix` contains shared packages and
   programs, while `personal.nix` and `work.nix` import common and add user-specific overrides
   (primarily git settings).

7. **Program configurations by category**: Programs are organized under `nix/home/programs/` in
   logical groupings (`shell/`, `terminal/`, `dev/`) rather than a flat structure.

8. **XDG-based config management**: Non-Nix application configs live in `config/` and are symlinked
   into `~/.config/` via home-manager's `xdg.configFile` (in `nix/home/programs/xdg.nix`).

9. **Configurable dotfiles path**: The `userConfig.dotfilesPath` makes the repository location
   configurable per-host, supporting different paths like `~/dotfiles` vs `~/Developer/dotfiles`.

## Consequences

### Positive

- **Adding a new machine** requires only creating a new host file and adding one line to `flake.nix`
- **Shared configuration changes** propagate to all machines automatically
- **Machine-specific customization** is isolated and easy to find
- **Different git identities** (personal vs work email) are cleanly separated
- **Clear separation of concerns**: System vs user, shared-vs-specific
- **Easy to locate configs**: Logical directory structure by category
- **Non-Nix configs tracked**: Application configs in `config/` are version-controlled
- **Safe refactoring** was possible with incremental commits that could be tested and rolled back

### Negative

- **More files to navigate** when making changes (though each file has a clear purpose)
- **Indirection**: Understanding the full configuration requires following imports across files
- **Path references** must be correct relative to where files are located
- **Some duplication** between personal and work user configs (though minimal)

### Neutral

- Modular structure makes it easier to extract parts into a shareable library if needed in the
  future
- Could theoretically support Linux machines by adding a `nix/nixos/` directory with similar
  structure

## Alternatives Considered

### 1. Conditional logic based on hostname

```nix
let
  hostname = builtins.getEnv "HOSTNAME";
  isWork = hostname == "Work-MacBook";
in {
  user.email = if isWork then "work@company.com" else "personal@email.com";
}
```

**Rejected because**: Less explicit, harder to see all configuration for a specific machine, and
`builtins.getEnv` doesn't work well with pure evaluation.

### 2. Separate flakes per machine

Each machine would have its own flake that imports shared modules from a common location.

**Rejected because**: Harder to keep inputs in sync, more complex setup, and the single-flake
approach is simpler for a personal dotfiles repo.

### 3. NixOS-style modules with options

Define proper NixOS module options for all configurable values.

**Rejected because**: Overkill for a personal dotfiles repo with only 2-3 machines. The current
approach is simpler while still being extensible.

### 4. Flat directory structure

Keep all configs in a single directory without categorization.

**Rejected because**: As the number of program configs grows, a flat structure becomes harder to
navigate. Categorization by purpose (shell, terminal, dev) improves discoverability.

## Migration Notes

During refactoring from the original structure:

1. Moved home-manager configs from `nix/darwin/home/` to `nix/home/programs/`
2. Moved user configs from `nix/darwin/users/` to `nix/home/users/`
3. Organized programs into categories: `shell/`, `terminal/`, `dev/`
4. Replaced hardcoded `~/dotfiles` paths with `userConfig.dotfilesPath`
5. Removed package duplication (packages installed by `programs.*` removed from `home.packages`)
6. Converted plain program config files to proper home-manager modules with consistent signatures

All changes were made incrementally with validation at each step.

## References

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [home-manager documentation](https://nix-community.github.io/home-manager/)
- [Nix flakes](https://nixos.wiki/wiki/Flakes)
- [ADR format](https://adr.github.io/)
