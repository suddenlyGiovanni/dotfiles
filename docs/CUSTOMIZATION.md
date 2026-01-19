# Customization Guide

This guide explains how to customize and extend the nix-darwin configuration for your needs.

> **Tip:** Run `just --list` from the repository root to see all available commands.

## Table of Contents

- [Quick Commands](#quick-commands)
- [Understanding the Structure](#understanding-the-structure)
- [Common Tasks](#common-tasks)
  - [Adding a New Package](#adding-a-new-package)
  - [Adding a New Homebrew Cask](#adding-a-new-homebrew-cask)
  - [Changing macOS System Preferences](#changing-macos-system-preferences)
  - [Adding a New Program Configuration](#adding-a-new-program-configuration)
  - [Adding a New Machine](#adding-a-new-machine)
  - [Customizing Git for a Specific Machine](#customizing-git-for-a-specific-machine)
- [Configuration Layers](#configuration-layers)
- [Testing Changes](#testing-changes)
- [Troubleshooting](#troubleshooting)

## Quick Commands

Common tasks using the `justfile` at the repository root:

```shell
# From ~/Developer/dotfiles
just fmt         # Format all Nix files
just lint        # Lint Nix files
just check       # Run all checks (format, lint, deadcode)
just build       # Build without applying
just switch      # Apply configuration
just update      # Update flake inputs
just validate    # Validate flake
just gc          # Garbage collect (keeps last 7 days)
```

## Understanding the Structure

```
dotfiles/
├── flake.nix        # Unified flake (darwin configs + dev environment)
├── flake.lock       # Pinned flake inputs
├── darwin.nix       # Darwin system configuration (imports modules/)
├── home.nix         # Home-manager user configuration (imports programs/)
├── nix.conf         # Nix configuration (symlinked to ~/.config/nix/)
├── justfile         # Task runner commands
├── .envrc           # direnv integration
├── hosts/           # Machine-specific configurations
│   ├── personal.nix # Personal MacBook
│   └── work.nix     # Work laptop
├── modules/         # Darwin system modules (auto-discovered)
│   ├── default.nix  # Auto-discovery module
│   ├── dock.nix     # Dock preferences
│   ├── finder.nix   # Finder preferences
│   ├── homebrew.nix # Homebrew casks, formulae, MAS apps
│   ├── security.nix # Firewall, Touch ID
│   └── ...          # Other system modules (trackpad, etc.)
├── programs/        # Home-manager program configs (auto-discovered)
│   ├── default.nix  # Auto-discovery module
│   ├── bat.nix      # Simple module: single file
│   ├── git/         # Complex module: directory with default.nix
│   │   └── default.nix
│   ├── zed/         # Co-located config: nix + json files
│   │   ├── default.nix
│   │   ├── settings.json
│   │   └── keymap.json
│   └── ...          # Other program modules (auto-discovered)
└── docs/
    ├── adr/         # Architecture Decision Records
    └── CUSTOMIZATION.md  # This file
```

### Which file do I edit?

| I want to...                                   | Edit this file                                     |
| ---------------------------------------------- | -------------------------------------------------- |
| Add a CLI tool (nix package)                   | `home.nix` → `home.packages`                       |
| Add a GUI app (Homebrew cask) for all machines | `modules/homebrew.nix` → `casks`                   |
| Add a GUI app for personal machine only        | `hosts/personal.nix` → `homebrew.casks`            |
| Add a GUI app for work machine only            | `hosts/work.nix` → `homebrew.casks`                |
| Change macOS Dock settings                     | `modules/dock.nix`                                 |
| Change macOS Finder settings                   | `modules/finder.nix`                               |
| Change macOS trackpad settings                 | `modules/trackpad.nix`                             |
| Change firewall/Touch ID settings              | `modules/security.nix`                             |
| Configure a program (git, fish, etc.)          | `programs/` (flat structure, auto-discovered)      |
| Change git identity                            | `programs/git/default.nix` (uses directory-based conditional includes) |
| Add a new machine                              | Create `hosts/new-machine.nix` + update `flake.nix`|
| Add config files (non-Nix)                     | Co-locate in `programs/<name>/` or add to root     |

## Common Tasks

### Adding a New Package

Packages installed via Nix go in `home.nix`:

```nix
# home.nix
{userConfig, pkgs, ...}: {
  home.packages = with pkgs; [
    # ... existing packages ...

    # Add your new package here
    ripgrep    # Fast grep alternative
    htop       # Interactive process viewer
    tree       # Directory listing
  ];

  # ... rest of config ...
}
```

**Finding package names:**

```shell
# Search for packages
nix search nixpkgs <package-name>

# Example
nix search nixpkgs ripgrep
```

### Adding a New Homebrew Cask

GUI applications are installed via Homebrew casks.

**For all machines** - edit `modules/homebrew.nix`:

```nix
# modules/homebrew.nix
{hostConfig, ...}: {
  homebrew = {
    # ... existing config ...

    casks = [
      # ... existing casks ...

      # Add your new cask here
      "spotify"
    ] ++ (hostConfig.homebrew.casks or []);
  };
}
```

**For a specific machine only** - edit the host file (e.g., `hosts/personal.nix`):

```nix
# hosts/personal.nix
{
  # ... other config ...

  homebrew = {
    enableRosetta = false;
    casks = [
      "discord"      # Personal only
      "transmission" # Personal only
      "whatsapp"     # Personal only
    ];
  };
}
```

**Finding cask names:**

```shell
brew search <app-name>
```

### Changing macOS System Preferences

macOS settings are split into focused modules in `modules/system-defaults/`:

**Dock settings** (`modules/dock.nix`):

```nix
_: {
  system.defaults.dock = {
    autohide = true;
    tilesize = 48;
    orientation = "left";  # "bottom", "left", or "right"
    show-recents = false;
    static-only = true;    # Show only open applications
  };
}
```

**Finder settings** (`modules/finder.nix`):

```nix
_: {
  system.defaults.finder = {
    AppleShowAllFiles = true;
    ShowPathbar = true;
    FXPreferredViewStyle = "clmv";  # Column view
    QuitMenuItem = true;   # Allow quitting Finder
  };
}
```

**Global settings** (`modules/nsglobaldomain.nix`):

```nix
_: {
  system.defaults.NSGlobalDomain = {
    AppleICUForce24HourTime = true;  # Use 24-hour time
    AppleShowAllExtensions = true;   # Show file extensions
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };
}
```

**Reference:** See
[nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for all available
settings.

### Adding a New Program Configuration

Programs in `programs/` are **auto-discovered** - just create the file and it's included!

**Simple module (single file):**

```nix
# programs/tmux.nix
{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;

    extraConfig = ''
      set -g status-style 'bg=#333333 fg=#5eacd3'
    '';
  };
}
```

**Complex module (directory with co-located config):**

```nix
# programs/myapp/default.nix
{pkgs, ...}: {
  programs.myapp = {
    enable = true;
  };

  xdg.configFile."myapp/settings.json".source = ./settings.json;
}
```

```json
// programs/myapp/settings.json
{
  "theme": "dark",
  "fontSize": 14
}
```

**Drafting a module (excluded from auto-discovery):**

Prefix with `_` to exclude from auto-discovery while working on it:

```shell
# These are ignored:
_tmux.nix
_neovim/
```

### Adding a New Machine

1. **Create a host configuration:**

```nix
# hosts/new-laptop.nix
{
  userConfig = {
    username = "myuser";
    fullName = "My Name";
    homeDirectory = "/Users/myuser";
    dotfilesPath = "/Users/myuser/Developer/dotfiles";
  };

  # Path to home-manager module
  userModule = ../home.nix;

  system = "aarch64-darwin";  # or "x86_64-darwin" for Intel

  hostname = "New-Laptop";  # Run: scutil --get LocalHostName

  homebrew = {
    enableRosetta = false;
    casks = [];  # Machine-specific casks
  };
}
```

2. **Add to `flake.nix`:**

```nix
# flake.nix
outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, mac-app-util, ... }: let
  # Import host configurations
  personalHost = import ./hosts/personal.nix;
  workHost = import ./hosts/work.nix;
  newLaptopHost = import ./hosts/new-laptop.nix;  # Add this

  # ... mkDarwinConfig function ...
in {
  darwinConfigurations = {
    ${personalHost.hostname} = mkDarwinConfig personalHost;
    ${workHost.hostname} = mkDarwinConfig workHost;
    ${newLaptopHost.hostname} = mkDarwinConfig newLaptopHost;  # Add this
  };
  # ...
}
```

3. **Apply on the new machine:**

```shell
sudo darwin-rebuild switch --flake ~/Developer/dotfiles#New-Laptop
```

### Customizing Git Identity

Git identity is handled via conditional includes in `programs/git/default.nix` based on directory paths:

```nix
# programs/git/default.nix
programs.git = {
  # ...
  includes = [
    {
      condition = "gitdir:~/Developer/work/";
      contents.user = {
        email = "giovanni@company.com";
        signingkey = "ssh-ed25519 AAAA...work-key";
      };
    }
    {
      condition = "gitdir:~/Developer/personal/";
      contents.user = {
        email = "giovanni@personal.com";
        signingkey = "ssh-ed25519 AAAA...personal-key";
      };
    }
  ];
};
```

This approach uses a single config with directory-based identity switching.

### Adding Non-Nix Config Files

For applications that don't have home-manager modules (or you prefer hand-crafted configs):

**Co-locate with program module (recommended)**

```shell
# Create program directory
mkdir -p programs/myapp

# Add default.nix that references the config
cat > programs/myapp/default.nix << 'EOF'
_: {
  xdg.configFile."myapp/config.json".source = ./config.json;
}
EOF

# Add the config file
cp ~/.config/myapp/config.json programs/myapp/

# Rebuild to apply
just switch
```

## Configuration Layers

Configuration is applied in layers, with later layers overriding earlier ones:

```
┌─────────────────────────────────────────────────┐
│  Host Config (hosts/personal.nix)               │  Machine-specific data
│  - hostname, username, dotfilesPath, casks      │
├─────────────────────────────────────────────────┤
│  Home Config (home.nix)                         │  User environment
│  - packages, imports programs/                  │
├─────────────────────────────────────────────────┤
│  Program Configs (programs/*.nix)               │  Program settings
│  - flat structure, auto-discovered              │
├─────────────────────────────────────────────────┤
│  Darwin Modules (modules/*.nix)                 │  System settings
│  - system-defaults/: macOS prefs                │
│  - homebrew.nix: shared casks/brews             │
│  - security.nix: firewall, Touch ID             │
├─────────────────────────────────────────────────┤
│  Darwin Config (darwin.nix)                     │  System setup
│  - imports modules/                             │
└─────────────────────────────────────────────────┘
```

## Testing Changes

### Build without applying

```shell
# From ~/Developer/dotfiles
just build

# Or directly:
darwin-rebuild build --flake .
```

### Check flake for errors

```shell
# From ~/Developer/dotfiles
just validate

# Or directly:
nix flake check
```

### Run all checks (format, lint, deadcode)

```shell
just check
```

### See what would change

```shell
just diff
```

### Apply changes

```shell
# From ~/Developer/dotfiles
just switch

# Or directly:
sudo darwin-rebuild switch --flake .
```

## Troubleshooting

### "Path does not exist in Git repository"

Nix flakes only see files tracked by git. Add new files:

```shell
git add <new-file>
```

### "error: attribute 'xyz' missing"

Usually means a typo in an attribute name or missing import. Check:

- Spelling of attribute names
- All required arguments are passed to functions
- Imports point to correct paths (relative to the importing file)

### Rolling back a broken change

```shell
# List previous generations
darwin-rebuild --list-generations

# Switch to a previous generation
sudo darwin-rebuild switch --rollback
```

### Finding available options

```shell
# Search nix-darwin options
man darwin-configuration.nix

# Search home-manager options
man home-configuration.nix

# Or online:
# https://daiderd.com/nix-darwin/manual/index.html
# https://nix-community.github.io/home-manager/options.xhtml
```

### Updating flake inputs

```shell
# From ~/Developer/dotfiles

# Update all inputs
just update

# Update a specific input
just update-input nixpkgs
```

After updating, rebuild to apply:

```shell
just switch
```

### Cleaning up old generations

```shell
# Remove generations older than 7 days
just gc

# Or remove all old generations except current
just gc-all
```

### Common Error: "evaluation aborted"

This usually means a syntax error in your Nix code. Run with `--show-trace` for details:

```shell
darwin-rebuild build --flake . --show-trace
```
