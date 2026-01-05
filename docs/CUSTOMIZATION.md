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
```

## Understanding the Structure

```
dotfiles/
├── flake.nix                    # Dev environment (formatters, linters, LSP)
├── justfile                     # Task runner commands
├── .envrc                       # direnv integration
├── config/                      # Non-Nix configs symlinked via home-manager
│   ├── zed/                     # Zed editor settings
│   └── git/                     # Git templates (.gitmessage)
├── nix/
│   ├── darwin/                  # nix-darwin system configuration
│   │   ├── flake.nix            # Entry point - defines darwin systems
│   │   ├── configuration.nix    # Core system settings
│   │   ├── modules/             # System-level modules
│   │   │   ├── homebrew.nix     # Homebrew casks, formulae, MAS apps
│   │   │   ├── security.nix     # Firewall, Touch ID
│   │   │   └── system-defaults.nix  # macOS preferences (dock, finder, etc.)
│   │   └── hosts/               # Machine-specific configs
│   │       ├── personal.nix     # Personal MacBook Air
│   │       └── work.nix         # Work laptop (template)
│   └── home/                    # home-manager user environment
│       ├── programs/            # Program configurations
│       │   ├── shell/           # zsh, fish, nushell
│       │   ├── terminal/        # starship, bat, eza, fd, fzf, zoxide
│       │   ├── dev/             # git, gh (GitHub CLI)
│       │   └── xdg.nix          # XDG base directories & config symlinks
│       └── users/               # User-specific configs
│           ├── common.nix       # Shared packages and programs
│           ├── personal.nix     # Personal git identity
│           └── work.nix         # Work git identity
└── docs/
    ├── adr/                     # Architecture Decision Records
    └── CUSTOMIZATION.md         # This file
```

### Which file do I edit?

| I want to...                                   | Edit this file                                                 |
| ---------------------------------------------- | -------------------------------------------------------------- |
| Add a CLI tool (nix package)                   | `nix/home/users/common.nix` → `home.packages`                  |
| Add a GUI app (Homebrew cask) for all machines | `nix/darwin/modules/homebrew.nix` → `casks`                    |
| Add a GUI app for personal machine only        | `nix/darwin/hosts/personal.nix` → `homebrew.casks`             |
| Add a GUI app for work machine only            | `nix/darwin/hosts/work.nix` → `homebrew.casks`                 |
| Change macOS Dock/Finder settings              | `nix/darwin/modules/system-defaults.nix`                       |
| Change firewall/Touch ID settings              | `nix/darwin/modules/security.nix`                              |
| Configure a program (git, fish, etc.)          | `nix/home/programs/{dev,shell,terminal}/`                      |
| Change git email for personal only             | `nix/home/users/personal.nix` → `programs.git.settings.user`   |
| Change git email for work only                 | `nix/home/users/work.nix` → `programs.git.settings.user`       |
| Add a new machine                              | Create `nix/darwin/hosts/new-machine.nix` + update `flake.nix` |
| Add config files (non-Nix)                     | Add to `config/` + symlink in `nix/home/programs/xdg.nix`      |

## Common Tasks

### Adding a New Package

Packages installed via Nix go in `nix/home/users/common.nix`:

```nix
# nix/home/users/common.nix
{userConfig}: {
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

**For all machines** - edit `nix/darwin/modules/homebrew.nix`:

```nix
# nix/darwin/modules/homebrew.nix
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

**For a specific machine only** - edit the host file (e.g., `nix/darwin/hosts/personal.nix`):

```nix
# nix/darwin/hosts/personal.nix
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

macOS settings are in `nix/darwin/modules/system-defaults.nix`:

```nix
# nix/darwin/modules/system-defaults.nix
_: {
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      tilesize = 48;
      orientation = "left";  # "bottom", "left", or "right"
      show-recents = false;
      static-only = true;    # Show only open applications
    };

    # Finder settings
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXPreferredViewStyle = "clmv";  # Column view
      QuitMenuItem = true;   # Allow quitting Finder
    };

    # Global macOS settings
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;  # Use 24-hour time
      AppleShowAllExtensions = true;   # Show file extensions
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
  };
}
```

**Reference:** See
[nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for all available
settings.

### Adding a New Program Configuration

Example: Adding tmux configuration.

1. **Create the program config file:**

```nix
# nix/home/programs/terminal/tmux.nix
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

2. **Import it in `nix/home/users/common.nix`:**

```nix
# nix/home/users/common.nix
{userConfig}: {
  imports = [
    # ... existing imports ...
    ../programs/terminal/tmux.nix
  ];

  # ... rest of config ...
}
```

### Adding a New Machine

1. **Create a host configuration:**

```nix
# nix/darwin/hosts/new-laptop.nix
{
  userConfig = {
    username = "myuser";
    fullName = "My Name";
    homeDirectory = "/Users/myuser";
    dotfilesPath = "/Users/myuser/Developer/dotfiles";
  };

  # Point to the appropriate user module
  userModule = ../../home/users/personal.nix;  # or work.nix

  system = "aarch64-darwin";  # or "x86_64-darwin" for Intel

  hostname = "New-Laptop";  # Run: scutil --get LocalHostName

  homebrew = {
    enableRosetta = false;
    casks = [];  # Machine-specific casks
  };
}
```

2. **Add to `nix/darwin/flake.nix`:**

```nix
# nix/darwin/flake.nix
outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }: let
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
sudo darwin-rebuild switch --flake ~/Developer/dotfiles/nix/darwin#New-Laptop
```

### Customizing Git for a Specific Machine

User-specific git settings are in `nix/home/users/personal.nix` or `work.nix`:

```nix
# nix/home/users/work.nix
{userConfig}: {
  imports = [
    ./common.nix
  ];

  # Override git settings for work
  programs.git.settings = {
    user = {
      name = "Giovanni Ravalico";
      email = "giovanni@company.com";
      signingkey = "ssh-ed25519 AAAA...";
    };

    # Work-specific git URLs
    url."git@github.company.com:".insteadOf = "https://github.company.com/";
  };
}
```

### Adding Non-Nix Config Files

For applications that don't have home-manager modules (or you prefer hand-crafted configs):

1. **Add config to `config/` directory:**

```shell
mkdir -p config/app-name
cp ~/.config/app-name/settings.json config/app-name/
```

2. **Symlink via `nix/home/programs/xdg.nix`:**

```nix
# nix/home/programs/xdg.nix
{userConfig}: {
  xdg = {
    enable = true;

    configFile = {
      # ... existing symlinks ...

      "app-name/settings.json" = {
        source = ../../../config/app-name/settings.json;
      };
    };
  };
}
```

3. **Rebuild to apply the symlink:**

```shell
just switch
```

## Configuration Layers

Configuration is applied in layers, with later layers overriding earlier ones:

```
┌─────────────────────────────────────────────────┐
│  Host Config (nix/darwin/hosts/personal.nix)    │  Machine-specific
│  - hostname, username, dotfilesPath, casks      │
├─────────────────────────────────────────────────┤
│  User Config (nix/home/users/personal.nix)      │  User-specific
│  - git email, signing keys, user overrides      │
├─────────────────────────────────────────────────┤
│  Common User (nix/home/users/common.nix)        │  Shared user settings
│  - packages, program imports                    │
├─────────────────────────────────────────────────┤
│  Program Configs (nix/home/programs/*/...)      │  Program settings
│  - shell/, terminal/, dev/ configurations       │
├─────────────────────────────────────────────────┤
│  Darwin Modules (nix/darwin/modules/*.nix)      │  Shared system settings
│  - system-defaults.nix: macOS prefs             │
│  - homebrew.nix: shared casks/brews             │
│  - security.nix: firewall, Touch ID             │
├─────────────────────────────────────────────────┤
│  Darwin Config (nix/darwin/configuration.nix)   │  Core system setup
│  - imports modules, user setup, nix settings    │
└─────────────────────────────────────────────────┘
```

## Testing Changes

### Build without applying

```shell
# From ~/Developer/dotfiles
just build

# Or directly:
darwin-rebuild build --flake ./nix/darwin
```

### Check flake for errors

```shell
# From ~/Developer/dotfiles
just validate

# Or directly:
nix flake check ./nix/darwin
```

### Run all checks (format, lint, deadcode)

```shell
just check
```

### See what would change

```shell
just build
nix store diff-closures /run/current-system ./result
```

### Apply changes

```shell
# From ~/Developer/dotfiles
just switch

# Or directly:
sudo darwin-rebuild switch --flake ./nix/darwin
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

# Or directly:
nix flake update --flake ./nix/darwin
```

After updating, rebuild to apply:

```shell
just switch
```

### Cleaning up old generations

```shell
# Remove generations older than 7 days
nix-collect-garbage --delete-older-than 7d

# Or remove all old generations except current
nix-collect-garbage -d
```

### Common Error: "evaluation aborted"

This usually means a syntax error in your Nix code. Run with `--show-trace` for details:

```shell
darwin-rebuild build --flake ./nix/darwin --show-trace
```
