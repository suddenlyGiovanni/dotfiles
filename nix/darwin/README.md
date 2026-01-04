# Darwin Configuration

This directory contains the nix-darwin system configuration for macOS machines.

## Structure

```
.
├── flake.nix           # Entry point - defines inputs and mkDarwinConfig helper
├── configuration.nix   # Core darwin settings (imports modules)
├── modules/
│   ├── system-defaults.nix   # macOS preferences (dock, finder, trackpad)
│   ├── homebrew.nix          # Homebrew casks and formulae
│   └── security.nix          # Firewall, Touch ID settings
├── hosts/
│   ├── personal.nix    # Personal MacBook Air settings
│   └── work.nix        # Work MacBook settings (template)
├── users/
│   ├── common.nix      # Shared home-manager packages and programs
│   ├── personal.nix    # Personal git identity
│   └── work.nix        # Work git identity
└── home/               # Program-specific configurations
    ├── git.nix         # Git aliases and settings
    ├── fish.nix        # Fish shell config
    ├── zsh.nix         # Zsh config
    ├── starship.nix    # Prompt configuration
    └── ...
```

## Usage

From the repository root (`~/dotfiles`):

```shell
# Build without applying
just build

# Apply configuration
just switch

# Apply a specific host
just switch-host Giovannis-MacBook-Air
```

Or directly with darwin-rebuild:

```shell
darwin-rebuild build --flake ~/dotfiles/nix/darwin
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#<hostname>
```

## Adding a New Machine

1. Create `hosts/<machine>.nix` with machine-specific settings
2. Add the host to `flake.nix` in `darwinConfigurations`
3. Run `just switch-host <hostname>` on the new machine

See [CUSTOMIZATION.md](../../docs/CUSTOMIZATION.md) for detailed instructions.