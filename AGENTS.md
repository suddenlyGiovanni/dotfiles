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
├── statix.toml      # Statix linter configuration
├── hosts/           # Machine-specific configs (personal.nix, work.nix)
├── lib/             # Shared helper functions (auto-discovery, etc.)
├── modules/         # Darwin system modules (flat, auto-discovered)
└── programs/        # Home-manager program configs (flat, auto-discovered)
```

### Two-Layer Configuration

1. **Darwin System Layer**
   - Entry point: `darwin.nix` (imports `modules/`)
   - Modules: `modules/` (homebrew.nix, security.nix, dock.nix, finder.nix, etc.)

2. **Home-Manager User Layer**
   - Entry point: `home.nix` (imports `programs/`)
   - Programs: `programs/` (flat structure with auto-discovery)
   - Co-located configs: Some programs have their own directories (e.g., `fish/`, `zed/`, `git/`)

3. **Machine-Specific Overrides**
   - Hosts: `hosts/` (per-machine data: hostname, homebrew casks, etc.)

### Key Files

- `flake.nix` - Unified entry point for darwin configurations and dev environment
- `darwin.nix` - Darwin system configuration (imports modules/)
- `home.nix` - Home-manager user configuration (imports programs/)
- `hosts/*.nix` - Machine-specific data (hostname, homebrew casks)
- `lib/auto-discovery.nix` - Shared module auto-discovery function
- `programs/session.nix` - Environment variables (EDITOR, XDG paths)
- `programs/fish/` - Fish shell configuration (default shell)
- `programs/1password.nix` - 1Password CLI + shell plugins
- `modules/homebrew.nix` - GUI apps via Homebrew
- `modules/*.nix` - macOS preferences (dock, finder, trackpad, security, etc.)

### Module Patterns

- **Flat auto-discovery**: Both `modules/` and `programs/` use shared `lib/auto-discovery.nix`
- **Explicit coordination**: Modules read `config.programs.<name>.enable` for shell/tool integrations
- **Co-located configs**: Complex modules use directories (e.g., `programs/zed/default.nix` + `programs/zed/settings.json`)
- **XDG env vars**: Program-specific XDG variables are set in their respective modules (e.g., `nodejs.nix` sets `NPM_CONFIG_CACHE`)

### Default Shell

Fish is the default login shell, configured in:
- `darwin.nix` - Sets `users.users.<name>.shell = pkgs.fish` and enables system-level fish
- `programs/fish/` - Modular fish config with abbreviations, aliases, and functions

Fish integrations include fzf, fd, bat, eza, and git helpers (`fe`, `fcd`, `gadd`, `gco`, `rg-fzf`).

### 1Password Integration

1Password provides:
- **SSH Agent**: All SSH operations use 1Password's SSH agent (`SSH_AUTH_SOCK`)
- **Git Signing**: Commits signed via 1Password SSH keys
- **Shell Plugins**: Biometric auth for CLI tools (`gh`, `awscli2`) via `op plugin run`

Configured in `programs/1password.nix` using the `onepassword-shell-plugins` flake input.

## Important Constraints

- **Git tracking required**: Nix flakes only see git-tracked files. Run `git add` on new files before building.
- **XDG compliance**: Environment variables redirect tool data to `~/.config`, `~/.local/share`, `~/.cache`, `~/.local/state`. See ADR-002.
- **SSH signing default**: Git uses 1Password SSH agent at `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.
- **No xdg.userDirs**: This is Linux-only and causes assertion failures on macOS.
- **Declarative SSH/GPG**: SSH config and GnuPG are managed via home-manager modules (`ssh.nix`, `gpg.nix`).
- **Fish is default shell**: After `just switch`, run `chsh -s /run/current-system/sw/bin/fish` to set login shell.

## Common Tasks

**Add a package**: Edit `home.packages` in `home.nix`

**Add a Homebrew cask**: Edit `modules/homebrew.nix` or host-specific file in `hosts/`

**Configure a program**: Add/edit file in `programs/` (auto-discovered)

**Add macOS system preference**: Add/edit file in `modules/` (auto-discovered)

**Add environment variable**: Edit `home.sessionVariables` in `programs/session.nix`

**Symlink a config file**: Add entry to `xdg.configFile` in `programs/xdg.nix`

**Co-locate program config**: Create a directory `programs/<program>/` with `default.nix` and config files

**Add a fish function**: Edit `programs/fish/functions.nix`

**Add a fish abbreviation**: Edit `programs/fish/abbreviations.nix`

## Documentation

- `docs/CUSTOMIZATION.md` - Detailed how-to guide with examples
- `docs/adr/` - Architecture Decision Records explaining design choices
- `docs/TASKS.md` - Task tracker for ongoing improvements