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

### Three-Layer Configuration

1. **Darwin System Layer** (`nix/darwin/`)
   - Core system: `nix/darwin/configuration.nix`
   - Modules: `nix/darwin/modules/` (homebrew, security, system-defaults/)
   - Hosts: `nix/darwin/hosts/` (per-machine overrides)

2. **Home-Manager User Layer** (`nix/home/`)
   - Programs: `nix/home/programs/` (flat structure with auto-discovery)
   - Users: `nix/home/users/` (common.nix for shared packages, personal.nix/work.nix for identity)
   - Co-located configs: Some programs have their own directories (e.g., `zed/`, `git/`) for complex configs

3. **Non-Nix Configs** (`config/`)
   - Symlinked via home-manager's `xdg.configFile` in `nix/home/programs/xdg.nix`
   - Used for configs that benefit from manual editing (git templates)

### Key Files

- `flake.nix` - Unified entry point for darwin configurations and dev environment
- `nix/home/users/common.nix` - Main package list and program imports
- `nix/home/programs/session.nix` - Environment variables (EDITOR, XDG paths)
- `nix/home/programs/xdg.nix` - XDG directories and config symlinks
- `nix/darwin/modules/homebrew.nix` - GUI apps via Homebrew
- `nix/darwin/modules/system-defaults/` - macOS preferences (dock, finder, trackpad, etc.)

### Module Patterns

- **Flat auto-discovery**: Programs in `nix/home/programs/` are auto-imported via `default.nix`
- **Co-located configs**: Complex programs use directories (e.g., `zed/default.nix` + `zed/settings.json`)
- **XDG env vars**: Program-specific XDG variables are set in their respective modules (e.g., `nodejs.nix` sets `NPM_CONFIG_CACHE`)

## Important Constraints

- **Git tracking required**: Nix flakes only see git-tracked files. Run `git add` on new files before building.
- **XDG compliance**: Environment variables redirect tool data to `~/.config`, `~/.local/share`, `~/.cache`, `~/.local/state`. See ADR-002.
- **SSH signing default**: Git uses 1Password SSH agent at `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.
- **No xdg.userDirs**: This is Linux-only and causes assertion failures on macOS.
- **Declarative SSH/GPG**: SSH config and GnuPG are managed via home-manager modules (`ssh.nix`, `gpg.nix`).

## Common Tasks

**Add a package**: Edit `home.packages` in `nix/home/users/common.nix`

**Add a Homebrew cask**: Edit `nix/darwin/modules/homebrew.nix` or host-specific file in `nix/darwin/hosts/`

**Configure a program**: Add/edit module in `nix/home/programs/`

**Add environment variable**: Edit `home.sessionVariables` in `nix/home/programs/session.nix`

**Symlink a config file**: Add entry to `xdg.configFile` in `nix/home/programs/xdg.nix`

**Co-locate program config**: Create a directory `nix/home/programs/<program>/` with `default.nix` and config files

## Documentation

- `docs/CUSTOMIZATION.md` - Detailed how-to guide with examples
- `docs/adr/` - Architecture Decision Records explaining design choices