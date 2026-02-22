# AGENTS.md

Guidance for AI coding agents working with this repository.

## Quick Reference

- **What**: Declarative macOS dotfiles using nix-darwin + home-manager + flake-parts
- **Architecture**: Dendritic pattern — each feature is a flake-parts module that can write to both darwin and home-manager sides (cross-cutting modules)
- **Entry point**: `flake.nix` → `modules/host-assembly.nix` orchestrates builds
- **Auto-discovery**: `import-tree` discovers all `.nix` files under `modules/` (prefix with `_` to exclude)

## Commands

```shell
just fmt          # Format Nix files
just lint         # Lint with statix
just check        # Run all checks (format, lint, deadcode, flake validation)
just build        # Build without applying
just switch       # Apply configuration (requires sudo)
just update       # Update flake inputs
just gc           # Garbage collect
```

## Critical Constraints

- **Git tracking required**: Run `git add` on new files before building (flakes only see tracked files)
- **No `xdg.userDirs`**: Linux-only module; causes assertion failures on macOS
- **Nushell is login shell**: Set by the nushell module via `users.users.*.shell`
- **1Password SSH**: Git signing uses `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
- **No specialArgs**: All values flow through the module system (flake-parts options, closure technique, or shared HM options)
- **Draft convention**: Prefix files with `_` to exclude from auto-discovery

## Module Structure

```
modules/
  options.nix          # Flake-parts level options (dotfiles.user, dotfiles.hosts)
  hosts.nix            # Concrete host data
  host-assembly.nix    # Builds darwinConfigurations (no specialArgs)
  features/
    hm-options.nix     # Shared HM-level options (hostname, sshKeys, agentSock)
    darwin-core.nix    # System plumbing (nixpkgs, systemPackages, fonts, user, nix)
    home-core.nix      # HM plumbing (username, homeDir, stateVersion, packages)
    # Cross-cutting modules (darwin + HM):
    fish/default.nix   # Shell: darwin (enable, vendor, pathsToLink) + HM (full config)
    zsh.nix            # Shell: darwin (env.shells, pathsToLink) + HM (config)
    nushell.nix        # Shell: darwin (env.shells, pathsToLink, login shell) + HM
    1password/         # Auth: darwin (cask) + HM (plugins, SSH keys, agent, XDG)
    docker.nix         # Tools: darwin (cask) + HM (CLI tools, XDG)
    zed/default.nix    # Editor: darwin (cask) + HM (config symlinks)
    ssh.nix            # SSH client: reads shared sshKeys + agentSock
    # Darwin-only modules:
    homebrew.nix       # Infrastructure + standalone casks
    dock.nix, finder.nix, trackpad.nix, ...  # macOS preferences
    # HM-only modules:
    git/default.nix, bat.nix, fzf.nix, starship.nix, ...
```

## File Locations

| Task | Location |
|------|----------|
| Add CLI package | `modules/features/home-core.nix` → `home.packages` |
| Add Homebrew cask (standalone) | `modules/features/homebrew.nix` → `casks` |
| Add Homebrew cask (with config) | Co-locate in the feature module's `flake.modules.darwin.*` side |
| Add host-specific cask | `modules/hosts.nix` → host's `homebrew.casks` |
| Configure a program | `modules/features/<name>.nix` or `modules/features/<name>/default.nix` |
| Add macOS preference | `modules/features/<name>.nix` |
| Add environment variable | Co-locate in the relevant feature module's `home.sessionVariables` |
| Add fish function/abbr | `modules/features/fish/_functions.nix` or `_abbreviations.nix` |
| Add SSH key | `modules/features/1password/default.nix` → `sshPublicKeys` + `agent.toml` |

## Documentation

For detailed guidance, see:

- [docs/CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) — How-to guide with examples
- [docs/adr/](./docs/adr/) — Architecture Decision Records (rationale for design choices)
- [docs/adr/007-dendritic-flake-parts-architecture.md](./docs/adr/007-dendritic-flake-parts-architecture.md) — Dendritic architecture ADR
- [docs/TASKS.md](./docs/TASKS.md) — Task tracker for ongoing work
