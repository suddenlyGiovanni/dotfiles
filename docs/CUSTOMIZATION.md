# Customization Guide

This guide explains how to customize and extend the nix-darwin configuration for your needs.

## Table of Contents

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

## Understanding the Structure

```
nix/darwin/
├── flake.nix              # Entry point - defines inputs and mkDarwinConfig helper
├── configuration.nix      # Shared darwin settings (system packages, macOS prefs)
├── hosts/
│   ├── personal.nix       # Machine-specific: hostname, username, architecture
│   └── work.nix           # Machine-specific: work machine settings
├── users/
│   ├── common.nix         # Shared home-manager: packages, programs
│   ├── personal.nix       # User-specific: personal git email/key
│   └── work.nix           # User-specific: work git email/key
└── home/                   # Program-specific configurations
    ├── git.nix
    ├── fish.nix
    ├── starship.nix
    └── ...
```

### Which file do I edit?

| I want to... | Edit this file |
|-------------|----------------|
| Add a CLI tool (nix package) | `users/common.nix` → `home.packages` |
| Add a GUI app (Homebrew cask) | `configuration.nix` → `homebrew.casks` |
| Change macOS Dock/Finder settings | `configuration.nix` → `system.defaults` |
| Change git config for all machines | `home/git.nix` |
| Change git email for personal only | `users/personal.nix` → `programs.git.settings.user` |
| Change git email for work only | `users/work.nix` → `programs.git.settings.user` |
| Add a new machine | Create `hosts/new-machine.nix` + update `flake.nix` |
| Configure a new program (e.g., tmux) | Create `home/tmux.nix` + import in `users/common.nix` |

## Common Tasks

### Adding a New Package

Packages installed via Nix go in `users/common.nix`:

```nix
# users/common.nix
home.packages = with pkgs; [
  # ... existing packages ...
  
  # Add your new package here
  ripgrep    # Fast grep alternative
  htop       # Interactive process viewer
  tree       # Directory listing
];
```

**Finding package names:**
```shell
# Search for packages
nix search nixpkgs <package-name>

# Example
nix search nixpkgs ripgrep
```

### Adding a New Homebrew Cask

GUI applications are typically installed via Homebrew casks in `configuration.nix`:

```nix
# configuration.nix
homebrew = {
  casks = [
    # ... existing casks ...
    
    # Add your new cask here
    "spotify"
    "slack"
    "zoom"
  ];
};
```

**Finding cask names:**
```shell
brew search <app-name>
```

### Changing macOS System Preferences

macOS settings are in `configuration.nix` under `system.defaults`:

```nix
# configuration.nix
system.defaults = {
  # Dock settings
  dock = {
    autohide = true;
    tilesize = 48;
    orientation = "left";  # "bottom", "left", or "right"
  };
  
  # Finder settings
  finder = {
    AppleShowAllFiles = true;
    ShowPathbar = true;
    FXPreferredViewStyle = "clmv";  # Column view
  };
  
  # Keyboard settings
  NSGlobalDomain = {
    KeyRepeat = 2;           # Faster key repeat
    InitialKeyRepeat = 15;   # Shorter delay before repeat
  };
};
```

**Reference:** See [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html) for all available settings.

### Adding a New Program Configuration

1. **Create the program config file:**

```nix
# home/tmux.nix
{ pkgs }:
{
  enable = true;
  
  # Program-specific settings
  terminal = "screen-256color";
  keyMode = "vi";
  
  extraConfig = ''
    set -g mouse on
    set -g base-index 1
  '';
}
```

2. **Import it in `users/common.nix`:**

```nix
# users/common.nix
programs = {
  # ... existing programs ...
  
  tmux = import ../../home/tmux.nix { inherit pkgs; };
};
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
  };

  # Point to the appropriate user module
  userModule = ../users/personal.nix;  # or ../users/work.nix

  system = "aarch64-darwin";  # or "x86_64-darwin" for Intel
  
  hostname = "New-Laptop";  # Run: scutil --get LocalHostName
  
  homebrew = {
    enableRosetta = false;
  };
}
```

2. **Add to `flake.nix`:**

```nix
# flake.nix
let
  personalHost = import ./hosts/personal.nix;
  workHost = import ./hosts/work.nix;
  newLaptopHost = import ./hosts/new-laptop.nix;  # Add this
in {
  darwinConfigurations = {
    ${personalHost.hostname} = mkDarwinConfig personalHost;
    ${workHost.hostname} = mkDarwinConfig workHost;
    ${newLaptopHost.hostname} = mkDarwinConfig newLaptopHost;  # Add this
  };
}
```

3. **Apply on the new machine:**

```shell
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#New-Laptop
```

### Customizing Git for a Specific Machine

User-specific git settings are in `users/personal.nix` or `users/work.nix`:

```nix
# users/work.nix
programs.git = let
  baseGit = import ../../home/git.nix { inherit pkgs; };
in
  baseGit // {
    settings = baseGit.settings // {
      user = {
        name = "Giovanni Ravalico";
        email = "giovanni@company.com";
        signingkey = "ssh-ed25519 AAAA...";
      };
      
      # You can also add work-specific git settings here
      url = {
        "git@github.company.com:" = {
          insteadOf = "https://github.company.com/";
        };
      };
    };
  };
```

## Configuration Layers

Configuration is applied in layers, with later layers overriding earlier ones:

```
┌─────────────────────────────────────────────────┐
│  Host Config (hosts/personal.nix)               │  Machine-specific
│  - hostname, username, architecture             │
├─────────────────────────────────────────────────┤
│  User Config (users/personal.nix)               │  User-specific
│  - git email, signing keys                      │
├─────────────────────────────────────────────────┤
│  Common User (users/common.nix)                 │  Shared user settings
│  - packages, program configs                    │
├─────────────────────────────────────────────────┤
│  Darwin Config (configuration.nix)              │  Shared system settings
│  - macOS prefs, homebrew, system packages       │
├─────────────────────────────────────────────────┤
│  Program Configs (home/*.nix)                   │  Base program settings
│  - git aliases, shell config, starship theme    │
└─────────────────────────────────────────────────┘
```

## Testing Changes

### Build without applying

```shell
darwin-rebuild build --flake ~/dotfiles/nix/darwin
```

### Check flake for errors

```shell
cd ~/dotfiles/nix/darwin
nix flake check
```

### See what would change

```shell
darwin-rebuild build --flake ~/dotfiles/nix/darwin
nvd diff /run/current-system result  # requires nvd package
```

### Apply changes

```shell
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin
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
- Imports point to correct paths

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
# https://nix-community.github.io/home-manager/options.html
```

### Updating flake inputs

```shell
cd ~/dotfiles/nix/darwin

# Update all inputs
nix flake update

# Update a specific input
nix flake lock --update-input nixpkgs
```

After updating, rebuild to apply:

```shell
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin
```
