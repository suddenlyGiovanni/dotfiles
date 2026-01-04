# Dotfiles

Personal Nix configuration for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).

Supports multiple machines with shared and host-specific settings.

## Development

This repo includes a Nix flake for development tooling. With [direnv](https://direnv.net/) installed:

```shell
cd ~/dotfiles
direnv allow
```

This provides: `alejandra` (formatter), `statix` (linter), `deadnix` (dead code finder), `nixd`/`nil` (LSP), and `just` (task runner).

### Common Tasks

```shell
just --list      # Show all available tasks
just fmt         # Format all Nix files
just lint        # Lint Nix files
just check       # Run all checks (format, lint, deadcode)
just switch      # Apply darwin configuration
just build       # Build without applying
```

## Quick Start

```shell
# 1. Clone
cd $HOME
git clone https://github.com/suddenlyGiovanni/dotfiles.git

# 2. Install Nix (via Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 3. Apply configuration
sudo -H nix run nix-darwin -- switch --flake ~/dotfiles/nix/darwin
```

## Update System

After modifying the configuration:

```shell
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin
```

## Available Configurations

| Hostname | Machine | User |
|----------|---------|------|
| `Giovannis-MacBook-Air` | Personal MacBook Air | personal git config |
| `Work-MacBook` | Work laptop (template) | work git config |

To apply a specific configuration:

```shell
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#<hostname>
```

## Documentation

| Document | Description |
|----------|-------------|
| [Customization Guide](./docs/CUSTOMIZATION.md) | How to add packages, configure programs, add new machines |
| [Architecture Decision Records](./docs/adr/) | Why things are designed the way they are |

## Project Structure

```
dotfiles/
├── flake.nix              # Development environment (linters, formatters)
├── justfile               # Task runner commands
├── .envrc                 # direnv integration
└── nix/darwin/
    ├── flake.nix              # Darwin system configuration entry point
    ├── configuration.nix      # Core system setup (imports modules)
    ├── modules/
    │   ├── system-defaults.nix  # macOS preferences (dock, finder, trackpad)
    │   ├── homebrew.nix         # Homebrew casks and formulae
    │   └── security.nix         # Firewall, Touch ID settings
    ├── hosts/                 # Machine-specific configs
    ├── users/                 # User-specific configs (git email, etc.)
    └── home/                  # Program configs (git, fish, starship, etc.)
```

See the [Customization Guide](./docs/CUSTOMIZATION.md) for details on which file to edit for common tasks.

## License

[MIT](./LICENSE)