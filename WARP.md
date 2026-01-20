# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This is a declarative macOS dotfiles repository using nix-darwin and home-manager with a Nix flake architecture. It manages system preferences, packages, and user environments across multiple machines (personal and work MacBooks) with shared configuration and host-specific overrides.

## Essential Commands

```shell
# Development workflow
just fmt          # Format Nix files with alejandra
just lint         # Lint with statix
just check        # Run all checks (format, lint, deadcode)
just build        # Build configuration without applying

# Apply changes
just switch       # Apply configuration (requires sudo)

# Maintenance
just update       # Update flake inputs
just gc           # Garbage collect (keeps last 7 days)
just generations  # List system generations
just rollback     # Rollback to previous generation

# Debugging
just diff         # Show what would change (requires nvd package)
just validate     # Validate flake
just repl         # Open nix repl with flake loaded
```

## Critical Constraints

1. **Git tracking required**: Nix flakes only see Git-tracked files. Always run `git add` on new files before building, otherwise you'll get "path does not exist" errors.

2. **No `xdg.userDirs` module**: This is Linux-only and causes assertion failures on macOS. Do not use it.

3. **Fish shell setup**: After `just switch`, the user must manually run `chsh -s /run/current-system/sw/bin/fish` to set fish as the default shell (logout/login required).

4. **1Password SSH agent**: Git signing uses `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`. Ensure 1Password is installed and SSH agent is enabled.

5. **Draft file convention**: Prefix files/directories with `_` to exclude them from auto-discovery (e.g., `_draft.nix`, `_experimental/`).

## Architecture

### Entry Points

- **`flake.nix`**: Flake definition with inputs, outputs, and `mkDarwinConfig` helper
- **`darwin.nix`**: System-level nix-darwin configuration (imports `modules/`)
- **`home.nix`**: User-level home-manager configuration (imports `programs/`)

### Directory Structure

```
dotfiles/
├── flake.nix              # Flake inputs/outputs, mkDarwinConfig helper
├── darwin.nix             # Shared darwin system config
├── home.nix               # Shared home-manager user config
├── hosts/                 # Machine-specific configs (data, not modules)
│   ├── personal.nix       # Personal MacBook configuration
│   └── work.nix           # Work MacBook configuration
├── modules/               # System-level nix-darwin modules (auto-discovered)
│   ├── default.nix        # Auto-discovery logic
│   ├── dock.nix           # Dock settings
│   ├── finder.nix         # Finder settings
│   ├── homebrew.nix       # Shared Homebrew configuration
│   ├── security.nix       # Firewall, Touch ID settings
│   └── ...                # Other macOS system preference modules
├── programs/              # User program configurations (auto-discovered)
│   ├── default.nix        # Auto-discovery logic
│   ├── fish/              # Fish shell (directory module)
│   │   ├── default.nix
│   │   ├── abbreviations.nix
│   │   ├── aliases.nix
│   │   └── functions.nix
│   ├── git/               # Git configuration (directory module)
│   │   ├── default.nix
│   │   └── .gitmessage    # Commit template
│   ├── bat.nix            # File modules for simple configs
│   ├── starship.nix
│   └── ...
├── lib/                   # Shared Nix utilities
│   └── auto-discovery.nix # Auto-discovery function for modules
└── docs/                  # Documentation
    ├── CUSTOMIZATION.md   # Detailed how-to guide
    ├── TASKS.md           # Task tracker
    └── adr/               # Architecture Decision Records
```

### Auto-Discovery System

Both `modules/` and `programs/` use auto-discovery via `lib/auto-discovery.nix`:

- **Single-file modules**: `foo.nix` → automatically imported
- **Directory modules**: `foo/default.nix` → automatically imported (used for complex configs with assets)
- **Excluded**: Files/directories starting with `_` (draft convention)
- **Excluded**: `default.nix` itself

This means you can add new program configurations or system modules by simply creating a `.nix` file—no import statements needed.

### Host Configuration Pattern

Host files (`hosts/*.nix`) are **data** (attribute sets), not NixOS modules:

```nix
# hosts/example.nix
{
  userConfig = {
    username = "user";
    fullName = "Full Name";
    homeDirectory = "/Users/user";
    dotfilesPath = "/Users/user/Developer/dotfiles";
  };
  
  userModule = ../home.nix;
  system = "aarch64-darwin";
  hostname = "Example-MacBook";  # Run: scutil --get LocalHostName
  
  homebrew = {
    enableRosetta = false;
    casks = [];  # Host-specific GUI apps
  };
}
```

The `mkDarwinConfig` helper in `flake.nix` converts these into full darwin configurations.

### Module Signature Conventions

All modules follow standard NixOS conventions:

```nix
# programs/example.nix or modules/example.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  # Configuration here
  programs.example = {
    enable = mkDefault true;
    # ...
  };
}
```

- Use full signature: `{ config, lib, pkgs, ... }:`
- Use `inherit (lib) mkDefault;` for cleaner code
- Apply `mkDefault` to values users might override
- Add descriptive header comments

## Common Editing Tasks

### Add a CLI Package

Edit `home.nix` → `home.packages`:

```nix
packages = with pkgs; [
  # ... existing packages
  ripgrep  # Add new package
];
```

Find packages: `nix search nixpkgs <name>`

### Add a GUI App (Homebrew Cask)

For **all machines**: `modules/homebrew.nix` → `casks`
For **specific machine**: `hosts/personal.nix` or `hosts/work.nix` → `homebrew.casks`

Find casks: `brew search <name>`

### Add a Program Configuration

Create a new file in `programs/`:

**Simple module** (single file):
```nix
# programs/tmux.nix
{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    # ...
  };
}
```

**Complex module** (directory with assets):
```nix
# programs/myapp/default.nix
{ ... }: {
  programs.myapp.enable = true;
  xdg.configFile."myapp/settings.json".source = ./settings.json;
}
```

### Change macOS System Preferences

Edit the appropriate module in `modules/`:

- `dock.nix` - Dock behavior
- `finder.nix` - Finder settings
- `nsglobaldomain.nix` - Global system settings
- `trackpad.nix` - Trackpad gestures
- `security.nix` - Firewall, Touch ID
- `custom-preferences.nix` - Settings not exposed via typed options

### Add Environment Variables

Edit `programs/session.nix` → `home.sessionVariables`

### Add Fish Shell Customizations

- **Abbreviations**: `programs/fish/abbreviations.nix` (expanded inline)
- **Aliases**: `programs/fish/aliases.nix` (not expanded)
- **Functions**: `programs/fish/functions.nix` (complex logic)

### Add a New Machine

1. Create `hosts/new-machine.nix` with host configuration
2. Edit `flake.nix`:
   - Add `newMachineHost = import ./hosts/new-machine.nix;`
   - Add `${newMachineHost.hostname} = mkDarwinConfig newMachineHost;` to `darwinConfigurations`
3. On new machine: `sudo darwin-rebuild switch --flake .#hostname`

## Testing Workflow

1. **Check syntax**: `just check` (format, lint, deadcode)
2. **Build first**: `just build` (ensures no evaluation errors)
3. **Review changes**: `just diff` (if `nvd` is installed)
4. **Apply**: `just switch`
5. **If broken**: `just rollback`

## Important Notes

### Version Control

- Changes must be `git add`ed before building (flakes requirement)
- The repository uses Git for version control
- All host-specific data is in version control

### Multiple Hosts

- Configuration is in flake outputs: `darwinConfigurations.<hostname>`
- Run `scutil --get LocalHostName` to get the correct hostname
- Build specific host: `darwin-rebuild build --flake .#<hostname>`
- Switch specific host: `sudo darwin-rebuild switch --flake .#<hostname>`

### Documentation

- `docs/CUSTOMIZATION.md` - Comprehensive how-to guide with examples
- `docs/adr/` - Architecture Decision Records explaining design choices
- `docs/TASKS.md` - Ongoing work and improvements

### References

All nix-darwin and home-manager options are documented:
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [home-manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)
