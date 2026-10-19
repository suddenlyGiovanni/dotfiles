# AGENTS.md

Guidance for AI coding agents working with this repository.

## Quick Reference

- **What**: Declarative macOS dotfiles using nix-darwin + home-manager + flake-parts
- **Architecture**: Dendritic pattern — each feature is a flake-parts module that can write to both darwin and home-manager sides (cross-cutting modules)
- **Entry point**: `flake.nix` → `modules/host-assembly.nix` orchestrates builds
- **Auto-discovery**: `import-tree` discovers all `.nix` files under `modules/features/` (prefix with `_` to exclude)

## Commands

`just --list` is the source of truth.

## Critical Constraints

- **Git tracking required**: Run `git add` on new files before building (flakes only see tracked files)
- **Nushell is the login shell**: never put POSIX syntax where `$SHELL -c` will run it
- **Rules fire on paths**: [.agents/rules/](./.agents/rules/) holds the constraints that apply to
  some files only. Read the rule before you edit a file it names; Claude Code loads it by itself.

  | Rule | Covers |
  |------|--------|
  | [nix-modules.md](./.agents/rules/nix-modules.md) | `flake.nix`, `modules/**/*.nix`: dendritic shape, discovery, no specialArgs, native option or writable link, no `xdg.userDirs`, zapped casks |
  | [nushell.md](./.agents/rules/nushell.md) | `*.nu` and the login-shell wiring: where nu's environment comes from, nu-lint config, string traps |
  | [git-signing.md](./.agents/rules/git-signing.md) | git, ssh and 1Password modules: 1Password signing, unattended runs |
  | [agent-tooling.md](./.agents/rules/agent-tooling.md) | `.agents/`, `.claude/`, `.opencode/`, `.mcp.json`: the shared/harness split, server lists, hook protocol |

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
- **Git hooks** (`flake.nix` → `perSystem.pre-commit`, git-hooks.nix): treefmt
  (`--fail-on-change`), statix, deadnix, nu-lint and merge-conflict markers on commit, convco on
  the message. The devshell installs them; `pre-commit run --all-files` runs them by hand. Never
  pass `--no-verify`: fix what they report.
- **Claude Code hooks** (`.claude/settings.json`). They are nu scripts; write new ones in nu, not
  POSIX shell:
  - SessionStart and CwdChanged (`.claude/hooks/direnv-prime.nu`) put the devshell of the current
    directory (the repo, or a `.worktrees/<name>`) on the Bash tool's PATH.
  - PreToolUse (`.claude/hooks/pre-tool-use.nu`) denies commands that have a `just` recipe
    (`darwin-rebuild`, `nix flake check|update`, …), a gate piped into `head`/`tail`,
    `--no-verify`, AI attribution, shell-authored files (`sed -i`, `tee`, `>` into the repo),
    installs outside nix, and writes to `flake.lock`, `result`, `.direnv/` or `.git/`. The deny
    reason names the path to take instead.
  - After every Write/Edit, `.claude/hooks/post-tool-use.nu` formats the file with treefmt, lints
    it, and reports back.
  - "Auto-formatted" means re-read the file before editing it again. Fix the lint findings in code
    you touched.
  - Stop (`.claude/hooks/stop-gate.nu`) runs `just check` when the turn leaves uncommitted
    `*.nix`/`*.nu`/`*.lua`/`*.toml`/`flake.lock` changes, and sends the turn back once if it fails.
- **LSP**: the in-repo plugin `.claude/plugins/dotfiles-lsp` (marketplace
  `.claude-plugin/marketplace.json`) wires `nu --lsp`, `nixd`, `lua-language-server`, `marksman`
  (`*.md`) and `taplo` (`*.toml`) into Claude Code's LSP tool. Claude Code installs it from the
  committed HEAD, so changes to it take effect once committed.
- **MCP**: `.mcp.json` starts mcpls (`.claude/mcpls.toml`), which bridges what the LSP tool can't
  reach: nixd's code actions (fixes), and just-lsp for the extensionless `justfile`.
- **Other harnesses**: shared agent tooling lives in `.agents/` (rules, skills, subagents, the full
  mcpls config); `.claude/` keeps only what is in Claude Code's own format, and links to the rest.
  [.agents/README.md](./.agents/README.md) maps it. OpenCode (`.opencode/opencode.jsonc`) runs
  none of the Claude Code hooks above: in it, run `just fmt` after editing and `just check` before
  you finish, and follow the PreToolUse rules by hand.

## Known Issues

- **zsh `initExtra` deprecation warning**: Build output shows `programs.zsh.initExtra is deprecated, use programs.zsh.initContent`. This comes from the `onepassword-shell-plugins` input (upstream `nix/shell-plugins.nix` sets `programs.zsh.initExtra`). Open upstream PRs: [#550](https://github.com/1Password/shell-plugins/pull/550), [#564](https://github.com/1Password/shell-plugins/pull/564). Run `nix flake update onepassword-shell-plugins` periodically to pick up the fix once merged.

## Documentation

For detailed guidance, see:

- [docs/CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) — How-to guide with examples
- [docs/adr/](./docs/adr/) — Architecture Decision Records (rationale for design choices)
- [docs/adr/007-flake-parts-dendritic-migration.md](./docs/adr/007-flake-parts-dendritic-migration.md) — Dendritic architecture ADR
- [docs/TASKS.md](./docs/TASKS.md) — Task tracker for ongoing work
