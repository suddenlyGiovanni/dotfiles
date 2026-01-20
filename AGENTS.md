# AGENTS.md

Guidance for AI coding agents working with this repository.

## Quick Reference

- **What**: Declarative macOS dotfiles using nix-darwin + home-manager
- **Entry points**: `darwin.nix` (system), `home.nix` (user)
- **Auto-discovery**: Files in `modules/` and `programs/` are automatically imported

## Commands

```shell
just fmt          # Format Nix files
just lint         # Lint with statix
just check        # Run all checks (format, lint, deadcode)
just build        # Build without applying
just switch       # Apply configuration (requires sudo)
just update       # Update flake inputs
just gc           # Garbage collect
```

## Critical Constraints

- **Git tracking required**: Run `git add` on new files before building (flakes only see tracked files)
- **No `xdg.userDirs`**: Linux-only module; causes assertion failures on macOS
- **Fish is default shell**: After `just switch`, user must run `chsh -s /run/current-system/sw/bin/fish`
- **1Password SSH**: Git signing uses `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
- **Draft convention**: Prefix files with `_` to exclude from auto-discovery

## File Locations

| Task | Location |
|------|----------|
| Add CLI package | `home.nix` → `home.packages` |
| Add Homebrew cask | `modules/homebrew.nix` or `hosts/*.nix` |
| Configure a program | `programs/<name>.nix` or `programs/<name>/default.nix` |
| Add macOS preference | `modules/<name>.nix` |
| Add environment variable | `programs/session.nix` |
| Add fish function/abbr | `programs/fish/functions.nix` or `abbreviations.nix` |

## Documentation

For detailed guidance, see:

- [docs/CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) — How-to guide with examples
- [docs/adr/](./docs/adr/) — Architecture Decision Records (rationale for design choices)
- [docs/TASKS.md](./docs/TASKS.md) — Task tracker for ongoing work