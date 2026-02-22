# Customization Guide

This guide explains how to customize and extend the nix-darwin configuration for your needs.

> **Architecture**: This repository uses the **dendritic pattern** with flake-parts.
> Each feature is a flake-parts module that can write to both the darwin (system) and
> home-manager (user) sides. See [ADR-007](./adr/007-dendritic-flake-parts-architecture.md).

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
just check       # Run all checks (format, lint, deadcode, flake validation)
just build       # Build without applying
just switch      # Apply configuration
just update      # Update flake inputs
just gc          # Garbage collect (keeps last 7 days)
```

## Which File Do I Edit?

| I want to...                                   | Edit this file                                                  |
| ---------------------------------------------- | --------------------------------------------------------------- |
| Add a CLI tool (nix package)                   | `modules/features/home-core.nix` → `home.packages`             |
| Add a GUI app (Homebrew cask) for all machines | `modules/features/homebrew.nix` → `casks` (standalone apps)    |
| Add a GUI app with HM config                   | Co-locate cask in the feature module's darwin side              |
| Add a GUI app for personal machine only        | `modules/hosts.nix` → personal host `homebrew.casks`           |
| Add a GUI app for work machine only            | `modules/hosts.nix` → work host `homebrew.casks`               |
| Change macOS Dock settings                     | `modules/features/dock.nix`                                    |
| Change macOS Finder settings                   | `modules/features/finder.nix`                                  |
| Change macOS trackpad settings                 | `modules/features/trackpad.nix`                                |
| Change menu bar clock settings                 | `modules/features/menuextra-clock.nix`                         |
| Change firewall/Touch ID settings              | `modules/features/security.nix`                                |
| Configure a program (git, bat, etc.)           | `modules/features/<name>.nix` (auto-discovered)                |
| Change git identity                            | `modules/features/git/default.nix` (directory-based includes)  |
| Add a new machine                              | `modules/hosts.nix` + `modules/options.nix`                    |
| Add config files (non-Nix)                     | Co-locate in `modules/features/<name>/`                        |
| Add a fish abbreviation                        | `modules/features/fish/_abbreviations.nix`                     |
| Add a fish alias                               | `modules/features/fish/_aliases.nix`                           |
| Add a fish function                            | `modules/features/fish/_functions.nix`                         |

## Common Tasks

### Adding a New Package

Packages installed via Nix go in `modules/features/home-core.nix`:

```nix
# modules/features/home-core.nix
home.packages = with pkgs; [
  # ... existing packages ...

  # Add your new package here
  ripgrep    # Fast grep alternative
  htop       # Interactive process viewer
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

GUI applications are installed via Homebrew casks.

**For standalone apps (no HM config needed)** - edit `modules/features/homebrew.nix`:

```nix
# modules/features/homebrew.nix
homebrew.casks = [
  # ... existing casks ...
  "spotify"
];
```

**For apps with HM configuration** - co-locate the cask in the feature module:

```nix
# modules/features/myapp.nix
_: {
  # Darwin side: install via Homebrew
  flake.modules.darwin.myapp = _: {
    homebrew.casks = ["myapp"];
  };

  # HM side: configure
  flake.modules.homeManager.myapp = { config, ... }: {
    xdg.configFile."myapp/config.json".source = ./config.json;
  };
}
```

**For a specific machine only** - edit `modules/hosts.nix`:

```nix
# modules/hosts.nix
hosts.personal.homebrew.casks = [
  "transmission"  # Personal only
];
```

**Finding cask names:**

```shell
brew search <app-name>
```

### Changing macOS System Preferences

macOS settings are split into focused modules in `modules/features/`:

**Dock settings** (`modules/features/dock.nix`):

```nix
_: {
  flake.modules.darwin.dock = _: {
    system.defaults.dock = {
      autohide = true;
      tilesize = 48;
      orientation = "left";
    };
  };
}
```

**Reference:** See
[nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options) for all available
settings.

### Adding a New Program Configuration

Programs in `modules/features/` are **auto-discovered** via `import-tree` — just create the file and it's included!

**Simple HM-only module (single file):**

```nix
# modules/features/tmux.nix
_: {
  flake.modules.homeManager.tmux = { pkgs, ... }: {
    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
    };
  };
}
```

**Cross-cutting module (darwin + HM):**

```nix
# modules/features/myshell.nix
_: {
  flake.modules.darwin.myshell = { pkgs, ... }: {
    environment.shells = [ pkgs.myshell ];
  };

  flake.modules.homeManager.myshell = { pkgs, ... }: {
    programs.myshell.enable = true;
  };
}
```

**Complex module (directory with co-located config):**

```nix
# modules/features/myapp/default.nix
_: {
  flake.modules.homeManager.myapp = _: {
    xdg.configFile."myapp/settings.json".source = ./settings.json;
  };
}
```

**Drafting a module (excluded from auto-discovery):**

Prefix with `_` to exclude from auto-discovery while working on it:

```shell
_tmux.nix     # Ignored by import-tree
_neovim/      # Ignored by import-tree
```

### Adding a New Machine

1. **Add host data in `modules/hosts.nix`:**

```nix
# modules/hosts.nix
_: {
  dotfiles.hosts.new-laptop = {
    hostname = "New-Laptop";  # Run: scutil --get LocalHostName
    homebrew.casks = [];      # Machine-specific casks
  };
}
```

2. **Update `justfile`** with the new hostname if needed.

3. **Apply on the new machine:**

```shell
sudo darwin-rebuild switch --flake ~/Developer/dotfiles#New-Laptop
```

### Customizing Git Identity

Git identity is handled via conditional includes in `modules/features/git/default.nix` based on directory paths:

```nix
includes = [
  {
    condition = "gitdir:~/Developer/work/";
    contents.user = {
      email = "giovanni@company.com";
      signingkey = config.dotfiles.sshKeys.git-signing;
    };
  }
];
```

The signing key is sourced from the shared `dotfiles.sshKeys` option (set by the 1password module).

### Customizing Fish Shell

Fish is configured in `modules/features/fish/`:

**Add an abbreviation**: `modules/features/fish/_abbreviations.nix`
**Add an alias**: `modules/features/fish/_aliases.nix`
**Add a function**: `modules/features/fish/_functions.nix`

### Adding Non-Nix Config Files

Co-locate config files with their module:

```shell
# Create program directory
mkdir -p modules/features/myapp

# Add default.nix that references the config
# Add the config file alongside it
modules/features/myapp/
  default.nix       # Nix module
  config.json       # Co-located config
```

## Configuration Layers

Configuration flows through the dendritic architecture:

```text
┌─────────────────────────────────────────────────┐
│  Flake-parts options (modules/options.nix)       │  Typed options
│  - dotfiles.user, dotfiles.hosts                │
├─────────────────────────────────────────────────┤
│  Host Assembly (modules/host-assembly.nix)       │  Orchestration
│  - Builds darwinConfigurations per host         │
│  - Merges all feature modules                   │
├─────────────────────────────────────────────────┤
│  Feature Modules (modules/features/*.nix)       │  Cross-cutting
│  - Each writes to darwin AND/OR HM sides        │
│  - Co-locates installation + configuration      │
├─────────────────────────────────────────────────┤
│  Shared HM Options (hm-options.nix)             │  Data bridges
│  - hostname, sshKeys, onePasswordAgentSock      │
└─────────────────────────────────────────────────┘
```

## Testing Changes

### Build without applying

```shell
just build
```

### Run all checks (format, lint, deadcode, flake validation)

```shell
just check
```

### Apply changes

```shell
just switch
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
- New files are `git add`-ed

### Rolling back a broken change

```shell
# List previous generations
just generations

# Rollback to previous
just rollback
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
just update              # Update all
just update-inputs nixpkgs  # Update specific input
just switch              # Rebuild to apply
```

### Cleaning up old generations

```shell
just gc       # Remove generations older than 7 days
just gc-all   # Remove all old generations except current
```

### 1Password shell plugins not working

Ensure 1Password CLI is installed and you're signed in:

```shell
op signin
```

The shell plugins (`gh`, `awscli2`) will prompt for biometric auth on first use.
