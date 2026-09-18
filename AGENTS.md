# AGENTS.md

Guidance for AI coding agents working with this repository.

## Quick Reference

- **What**: Declarative macOS dotfiles using nix-darwin + home-manager + flake-parts
- **Architecture**: Dendritic pattern — each feature is a flake-parts module that can write to both darwin and home-manager sides (cross-cutting modules)
- **Entry point**: `flake.nix` → `modules/host-assembly.nix` orchestrates builds
- **Auto-discovery**: `import-tree` discovers all `.nix` files under `modules/` (prefix with `_` to exclude)

## Commands

```shell
just fmt          # Format with treefmt (Nix, Nu, Lua; see treefmt.toml)
just lint         # Lint with statix and nu-lint
just check        # Run all checks (format, lint, deadcode, flake validation)
just build        # Build current host without applying
just build-all    # Build all host configurations
just switch       # Apply configuration (requires sudo)
just update       # Update flake inputs
just gc           # Garbage collect
```

## Critical Constraints

- **Git tracking required**: Run `git add` on new files before building (flakes only see tracked files)
- **No `xdg.userDirs`**: Linux-only module; causes assertion failures on macOS
- **Nushell is the login shell**: `users.users.*.shell` in `nushell/default.nix`, applied because `darwin-core.nix` lists the user in `users.knownUsers` (ADR-008). nu gets its environment from `/etc/login-environment.sh` (`session.nix`) in `nushell/env.nu`; GUI apps get the same variables from the `login-environment` launchd agent. Never put POSIX syntax where `$SHELL -c` will run it
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
    nushell/           # Login shell: darwin (env.shells, pathsToLink, shell) + HM (env.nu, config.nu)
    session.nix        # Session vars (HM) + /etc/login-environment.sh and its launchd agent (darwin)
    fish/default.nix   # Fallback shell: darwin (enable, vendor, env.shells) + HM (full config)
    zsh.nix            # Shell: darwin (env.shells, pathsToLink) + HM (config)
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
| Add nu command | `modules/features/nushell/config.nu` |
| Add abbreviation / alias (nu + fish) | `modules/features/fish/_abbreviations.nix` or `_aliases.nix` (nushell/default.nix imports both) |
| Add fish function | `modules/features/fish/_functions.nix` |
| Add SSH key | `modules/features/1password/default.nix` → `sshPublicKeys` + `agent.toml` |

## Feedback Loop

The devshell (`flake.nix` → `devShells.default`, loaded by direnv) carries every formatter, linter
and language server, and every check uses those same binaries:

- **Format**: `treefmt.toml` is the one table: alejandra (`*.nix`), nufmt (`*.nu`) and stylua
  (`*.lua`). `nix fmt`, `just fmt`, the `formatting` flake check and Zed (`.zed/settings.json`) all
  route through it.
- **Lint**: statix and deadnix (`*.nix`), nu-lint (`*.nu`, always with `--config .nu-lint.toml`).
- **Claude Code hooks** (`.claude/settings.json`). They are nu scripts; write new ones in nu, not
  POSIX shell:
  - SessionStart (`.claude/hooks/direnv-prime.nu`) puts the devshell on the Bash tool's PATH.
  - After every Write/Edit, `.claude/hooks/post-tool-use.nu` formats the file with treefmt, lints
    it, and reports back.
  - "Auto-formatted" means re-read the file before editing it again. Fix the lint findings in code
    you touched.
- **LSP**: the in-repo plugin `.claude/plugins/dotfiles-lsp` (marketplace
  `.claude-plugin/marketplace.json`) wires `nu --lsp` and `nixd` into Claude Code's LSP tool.
  Claude Code installs it from the committed HEAD, so changes to it take effect once committed.

## Known Issues

- **zsh `initExtra` deprecation warning**: Build output shows `programs.zsh.initExtra is deprecated, use programs.zsh.initContent`. This comes from the `onepassword-shell-plugins` input (upstream `nix/shell-plugins.nix` sets `programs.zsh.initExtra`). Open upstream PRs: [#550](https://github.com/1Password/shell-plugins/pull/550), [#564](https://github.com/1Password/shell-plugins/pull/564). Run `nix flake update onepassword-shell-plugins` periodically to pick up the fix once merged.

## Documentation

For detailed guidance, see:

- [docs/CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) — How-to guide with examples
- [docs/adr/](./docs/adr/) — Architecture Decision Records (rationale for design choices)
- [docs/adr/007-dendritic-flake-parts-architecture.md](./docs/adr/007-dendritic-flake-parts-architecture.md) — Dendritic architecture ADR
- [docs/TASKS.md](./docs/TASKS.md) — Task tracker for ongoing work
