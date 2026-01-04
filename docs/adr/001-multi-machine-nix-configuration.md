# ADR-001: Multi-Machine Nix Configuration

## Status

Accepted

## Date

2025-01

## Context

The dotfiles repository was originally designed for a single macOS machine (personal MacBook Air) using nix-darwin and home-manager. With the upcoming need to set up a work MacBook while retaining the personal machine, we needed a way to:

1. Share common configuration between machines (system preferences, packages, shell configs)
2. Allow machine-specific settings (hostname, architecture)
3. Allow user-specific settings (git email, SSH signing keys)
4. Keep the configuration maintainable and DRY (Don't Repeat Yourself)
5. Enable safe, incremental changes without breaking the working setup

The original configuration had everything in a single `flake.nix` with an inline `configuration` function and hardcoded values like username (`suddenlygiovanni`) and home directory (`/Users/suddenlygiovanni`).

## Decision

We restructured the nix-darwin configuration into a modular, multi-machine architecture:

```
dotfiles/nix/darwin/
├── flake.nix              # Entry point with mkDarwinConfig helper function
├── configuration.nix      # Shared darwin system settings
├── hosts/
│   ├── personal.nix       # Personal MacBook Air specifics
│   └── work.nix           # Work MacBook specifics
├── users/
│   ├── common.nix         # Shared home-manager settings
│   ├── personal.nix       # Personal user (git config, etc.)
│   └── work.nix           # Work user (work git config, etc.)
└── home/                   # Program-specific configs (git, fish, etc.)
```

### Key Design Decisions

1. **Host configurations as data, not modules**: Host files (`hosts/*.nix`) are simple attribute sets containing machine-specific values, not NixOS modules. This keeps them simple and declarative.

2. **`mkDarwinConfig` helper function**: A single function in `flake.nix` that takes a host configuration and produces a complete darwin system. This ensures consistency and reduces duplication.

3. **User configuration passed via `specialArgs`**: The `userConfig` attribute set is passed through `specialArgs` to all modules, making user-specific values available everywhere without hardcoding.

4. **Separation of users from hosts**: User configurations (`users/*.nix`) are separate from host configurations, allowing the same user config to be reused across machines, or different users on the same machine type.

5. **Common base with overrides**: `users/common.nix` contains shared packages and programs, while `users/personal.nix` and `users/work.nix` import common and add user-specific overrides (primarily git settings).

## Consequences

### Positive

- **Adding a new machine** requires only creating a new host file and adding one line to `flake.nix`
- **Shared configuration changes** propagate to all machines automatically
- **Machine-specific customization** is isolated and easy to find
- **Different git identities** (personal vs work email) are cleanly separated
- **Safe refactoring** was possible with incremental commits that could be tested and rolled back

### Negative

- **More files to navigate** when making changes (though each file has a clear purpose)
- **Indirection**: Understanding the full configuration requires following imports across files
- **Path references** must be correct relative to where files are located (caused a bug during initial implementation)

### Neutral

- The `home/` directory with program-specific configs (git.nix, fish.nix, etc.) was kept as-is since it was already well-organized
- Homebrew casks are still in the shared `configuration.nix` - could be split per-host in the future if needed

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

**Rejected because**: Less explicit, harder to see all configuration for a specific machine, and `builtins.getEnv` doesn't work well with pure evaluation.

### 2. Separate flakes per machine

Each machine would have its own flake that imports shared modules from a common location.

**Rejected because**: Harder to keep inputs in sync, more complex setup, and the single-flake approach is simpler for a personal dotfiles repo.

### 3. NixOS-style modules with options

Define proper NixOS module options for all configurable values.

**Rejected because**: Overkill for a personal dotfiles repo with only 2-3 machines. The current approach is simpler while still being extensible.

## References

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [home-manager documentation](https://nix-community.github.io/home-manager/)
- [Nix flakes](https://nixos.wiki/wiki/Flakes)
- [ADR format](https://adr.github.io/)