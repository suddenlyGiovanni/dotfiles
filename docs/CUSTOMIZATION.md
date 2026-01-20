# Customization Guide

This guide explains how to customize and extend the nix-darwin configuration for your needs.

> **Tip:** Run `just --list` from the repository root to see all available commands.

## Table of Contents

- [Quick Commands](#quick-commands)
- [Which File Do I Edit?](#which-file-do-i-edit)
- [Common Tasks](#common-tasks)
  - [Adding a New Package](#adding-a-new-package)
  - [Adding a New Homebrew Cask](#adding-a-new-homebrew-cask)
  - [Changing macOS System Preferences](#changing-macos-system-preferences)
  - [Adding a New Program Configuration](#adding-a-new-program-configuration)
  - [Adding a New Machine](#adding-a-new-machine)
  - [Customizing Git Identity](#customizing-git-identity)
  - [Customizing Fish Shell](#customizing-fish-shell)
  - [Adding Non-Nix Config Files](#adding-non-nix-config-files)
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
just gc          # Garbage collect (keeps last 7 days)
```

## Which File Do I Edit?

| I want to...                                   | Edit this file                                     |
| ---------------------------------------------- | -------------------------------------------------- |
| Add a CLI tool (nix package)                   | `home.nix` → `home.packages`                       |
| Add a GUI app (Homebrew cask) for all machines | `modules/homebrew.nix` → `casks`                   |
| Add a GUI app for personal machine only        | `hosts/personal.nix` → `homebrew.casks`            |
| Add a GUI app for work machine only            | `hosts/work.nix` → `homebrew.casks`                |
| Change macOS Dock settings                     | `modules/dock.nix`                                 |
| Change macOS Finder settings                   | `modules/finder.nix`                               |
| Change macOS trackpad settings                 | `modules/trackpad.nix`                             |
| Change menu bar clock settings                 | `modules/menuextra-clock.nix`                      |
| Change firewall/Touch ID settings              | `modules/security.nix`                             |
| Configure a program (git, bat, etc.)           | `programs/` (flat structure, auto-discovered)      |
| Change git identity                            | `programs/git/default.nix` (directory-based conditional includes) |
| Add a new machine                              | Create `hosts/new-machine.nix` + update `flake.nix`|
| Add config files (non-Nix)                     | Co-locate in `programs/<name>/` or add to root     |
| Add a fish abbreviation                        | `programs/fish/abbreviations.nix`                  |
| Add a fish alias                               | `programs/fish/aliases.nix`                        |
| Add a fish function                            | `programs/fish/functions.nix`                      |

## Common Tasks

### Adding a New Package

Packages installed via Nix go in `home.nix`:

```nix
# home.nix
{pkgs, ...}: {
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

macOS settings are split into focused modules in `modules/`:

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
    NewWindowTarget = "Home";  # New windows open to home folder
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
    "com.apple.keyboard.fnState" = true;  # Use F1-F12 as function keys
  };
}
```

**Menu bar clock** (`modules/menuextra-clock.nix`):

```nix
_: {
  system.defaults.menuExtraClock = {
    Show24Hour = true;
    ShowDayOfWeek = true;
    ShowDate = 0;  # 0 = When space allows
  };
}
```

**Additional settings via CustomUserPreferences** (`modules/custom-preferences.nix`):

For settings not exposed via typed nix-darwin options:

```nix
_: {
  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      AppleFirstWeekday = { gregorian = 2; };  # Week starts Monday
    };
    "com.apple.AppleMultitouchTrackpad" = {
      TrackpadThreeFingerHorizSwipeGesture = 2;
    };
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
outputs = { self, nixpkgs, nix-darwin, home-manager, ... }: let
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
chsh -s /run/current-system/sw/bin/fish  # Set fish as default shell
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

### Customizing Fish Shell

Fish is the default shell, configured in `programs/fish/`:

**Add an abbreviation** (expanded inline as you type):

```nix
# programs/fish/abbreviations.nix
{userConfig}: {
  # Navigation
  ".." = "cd ..";
  "..." = "cd ../..";

  # Your custom abbreviations
  k = "kubectl";
  tf = "terraform";
}
```

**Add an alias** (not expanded, for complex commands):

```nix
# programs/fish/aliases.nix
{
  ll = "eza --all --long --icons --header";
  cat = "bat --paging=never";

  # Your custom aliases
  serve = "python -m http.server";
}
```

**Add a function** (for complex logic):

```nix
# programs/fish/functions.nix
{config, ...}: {
  # Your custom function
  myfunction = {
    description = "Does something useful";
    argumentNames = ["arg1" "arg2"];
    body = ''
      echo "Got: $arg1 and $arg2"
    '';
  };
}
```

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

```text
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
│  - dock, finder, trackpad, security, etc.       │
│  - homebrew.nix: shared casks/brews             │
├─────────────────────────────────────────────────┤
│  Darwin Config (darwin.nix)                     │  System setup
│  - imports modules/                             │
│  - sets fish as default shell                   │
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

### Fish shell not active after switch

After applying the configuration, set fish as your login shell:

```shell
chsh -s /run/current-system/sw/bin/fish
```

Then log out and log back in, or open a new terminal.

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

### 1Password shell plugins not working

Ensure 1Password CLI is installed and you're signed in:

```shell
op signin
```

The shell plugins (`gh`, `awscli2`) will prompt for biometric auth on first use.