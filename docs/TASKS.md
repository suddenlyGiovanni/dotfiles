# Task Tracker

> **Last Updated**: 2026-02-22

## Current Status

The dotfiles repository uses a **dendritic architecture** with flake-parts:

- **Flake-parts modules**: Every `.nix` file is a flake-parts module
- **Cross-cutting features**: Modules co-locate darwin + HM concerns (fish, zsh, nushell, 1password, docker, zed)
- **import-tree auto-discovery**: New modules in `modules/features/` are automatically discovered
- **Typed host options**: `dotfiles.hosts.*` in `modules/options.nix`
- **Shared HM options**: `dotfiles.{hostname,sshKeys,onePasswordAgentSock}` bridge data between modules
- **No specialArgs**: All values flow through the module system
- **1Password integration**: SSH agent + shell plugins + shared keys via options

See [ADR-007](./adr/007-flake-parts-dendritic-migration.md) for architecture decisions.

---

## Open Discussions

- [ ] **Split the development environment from the configuration that is switched** (2026-11-16).
  One flake holds both: the `perSystem` devshell, formatter table and git hooks for working on
  this repo, and the darwin and Home Manager configurations that `just switch` applies. The
  question is whether the development side moves to devenv, as the team's repositories do.
  - For: the team's pattern; devenv's hooks are the same git-hooks.nix module, so the checks
    carry over unchanged.
  - Against: a second lock file means a second nixpkgs and more copies in the Nix store
    ([nix-store-sharing.md](./research/nix-store-sharing.md)).
  - Decided so far: settle the feedback loop first (`just lint` runs the git hooks at every
    stage), then revisit.

---

## Planned

- [ ] **Claude Code configuration from one source** (decided 2026-11-16,
  [claude-config-locations.md](./research/claude-config-locations.md)). Claude Code's own formats
  are the source of truth; Nix only places files and sets `CLAUDE_CONFIG_DIR`.
  - Move each `programs.claude-code.skills` / `.mcpServers` use into a plugin of the
    `suddenlygiovanni-dotfiles` marketplace, enabled in the tracked `settings.json`: `hey-cli.nix`
    (MCP server; call `hey` by name), `gws.nix`, `hunk.nix`, `herdr/`, the `ast-grep` skill
    (flake input). Each loses its Nix pin, unless the plugin references a pinned git source.
  - Then `programs.claude-code` keeps only `configDir` and `package = null`.
- [ ] **Work-global Claude layer in `infrastructure/developer`** (decided 2026-11-16).
  - A team plugin marketplace inside that repository: work conventions, shared skills, team MCP
    servers.
  - Each work repository names it in its committed `.claude/settings.json`
    (`extraKnownMarketplaces`, `enabledPlugins`); the team's machine setup enables it at user
    scope on work Macs. The personal host never sees it.
  - Until then, work-wide instructions live in `modules/features/agents/work/AGENTS.md`, linked
    as `~/Developer/work/CLAUDE.md` on the work host; move what every colleague should share into
    the team repository.
- [ ] **Mobile toolchain on XDG paths, set here first** (decided 2026-11-16,
  [mobile-toolchain-locations.md](./research/mobile-toolchain-locations.md)). Work host only.
  - Phase 1, done: the `jetbrains-toolbox` cask; `android.nix` (SDK, AVDs, preferences, Gradle
    home, JDK, Android Studio's folders); `cocoapods.nix`; the hand migration; agent commands
    loading the login environment themselves.
  - Phase 1, open: a Gradle sync of `connect` in Android Studio; Toolbox's per-tool JVM options
    location; an `xcode` module (`xcodes`, a declared version, `xcode-provision`, an activation
    check).
  - Phase 2, later: WebStorm on the same layout; merge requests to `infrastructure/developer`;
    `.xcode-version` and `GEM_HOME` in the project repos.

---

## Icebox (Future Improvements)

Potential enhancements, not currently prioritized:

- [ ] **Add more fish plugins** — fzf.fish, z, autopair.fish
- [ ] **Add Neovim/Helix configuration** — `modules/features/neovim/` or `modules/features/helix/`
- [ ] **Add tmux configuration** — `modules/features/tmux.nix`
- [ ] **Module testing patterns** — `_test.nix` convention
- [ ] **Documentation generation** — Auto-generate docs from module structure
