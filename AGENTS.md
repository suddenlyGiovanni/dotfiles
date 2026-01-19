# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

This is a declarative Nix-based dotfiles repository for macOS using nix-darwin and home-manager. It manages system configuration, user environment, and dotfiles for multiple machines.

## Commands

Development environment loads automatically via direnv (`direnv allow`). Use `just` for all operations:

```shell
just fmt          # Format all Nix files with alejandra
just lint         # Lint with statix
just check        # Run all checks (format, lint, deadcode)
just build        # Build configuration without applying
just switch       # Apply configuration (requires sudo)
just update       # Update all flake inputs
just gc           # Garbage collect (keeps last 7 days)
```

For host-specific operations:
```shell
just build-host <hostname>
just switch-host <hostname>
```

## Architecture

### Unified Root Flake

The repository uses a single `flake.nix` at the root that exposes:
- `darwinConfigurations` - System configurations for each machine
- `devShells` - Development environment (linters, formatters, LSP)
- `formatter` - Nix formatter (alejandra)

### Flat Directory Structure

```
dotfiles/
├── flake.nix        # Unified entry point (darwin configs + dev environment)
├── darwin.nix       # Darwin system configuration (imports modules/)
├── home.nix         # Home-manager user configuration (imports programs/)
├── nix.conf         # Nix configuration (symlinked to ~/.config/nix/)
├── hosts/           # Machine-specific configs (personal.nix, work.nix)
├── modules/         # Darwin system modules (flat, auto-discovered)
└── programs/        # Home-manager program configs (flat, auto-discovered)
```

### Two-Layer Configuration

1. **Darwin System Layer**
   - Entry point: `darwin.nix` (imports `modules/`)
   - Modules: `modules/` (homebrew.nix, security.nix, system-defaults/)

2. **Home-Manager User Layer**
   - Entry point: `home.nix` (imports `programs/`)
   - Programs: `programs/` (flat structure with auto-discovery)
   - Co-located configs: Some programs have their own directories (e.g., `zed/`, `git/`)

3. **Machine-Specific Overrides**
   - Hosts: `hosts/` (per-machine data: hostname, homebrew casks, etc.)

### Key Files

- `flake.nix` - Unified entry point for darwin configurations and dev environment
- `darwin.nix` - Darwin system configuration (imports modules/)
- `home.nix` - Home-manager user configuration (imports programs/)
- `hosts/*.nix` - Machine-specific data (hostname, homebrew casks)
- `programs/session.nix` - Environment variables (EDITOR, XDG paths)
- `modules/homebrew.nix` - GUI apps via Homebrew
- `modules/*.nix` - macOS preferences (dock, finder, trackpad, security, etc.)

### Module Patterns

- **Flat auto-discovery**: Both `modules/` and `programs/` use auto-import via `default.nix`
- **Co-located configs**: Complex modules use directories (e.g., `programs/zed/default.nix` + `programs/zed/settings.json`)
- **XDG env vars**: Program-specific XDG variables are set in their respective modules (e.g., `nodejs.nix` sets `NPM_CONFIG_CACHE`)

## Important Constraints

- **Git tracking required**: Nix flakes only see git-tracked files. Run `git add` on new files before building.
- **XDG compliance**: Environment variables redirect tool data to `~/.config`, `~/.local/share`, `~/.cache`, `~/.local/state`. See ADR-002.
- **SSH signing default**: Git uses 1Password SSH agent at `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.
- **No xdg.userDirs**: This is Linux-only and causes assertion failures on macOS.
- **Declarative SSH/GPG**: SSH config and GnuPG are managed via home-manager modules (`ssh.nix`, `gpg.nix`).

## Common Tasks

**Add a package**: Edit `home.packages` in `home.nix`

**Add a Homebrew cask**: Edit `modules/homebrew.nix` or host-specific file in `hosts/`

**Configure a program**: Add/edit file in `programs/` (auto-discovered)

**Add macOS system preference**: Add/edit file in `modules/` (auto-discovered)

**Add environment variable**: Edit `home.sessionVariables` in `programs/session.nix`

**Symlink a config file**: Add entry to `xdg.configFile` in `programs/xdg.nix`

**Co-locate program config**: Create a directory `programs/<program>/` with `default.nix` and config files

## Documentation

- `docs/CUSTOMIZATION.md` - Detailed how-to guide with examples
- `docs/adr/` - Architecture Decision Records explaining design choices