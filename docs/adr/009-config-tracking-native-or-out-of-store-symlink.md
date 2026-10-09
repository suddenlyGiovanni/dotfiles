# ADR-009: Configuration Tracking — Native Option or Writable Symlink

## Status

Accepted

## Date

2026-10-09

## Context

Home Manager can place a tool's configuration in two ways:

- A **native option**, such as `programs.git.settings` or `programs.claude-code.settings`, renders
  the file into the Nix store and links it into the home directory. The file is read-only.
- **`config.lib.file.mkOutOfStoreSymlink`** links the home-directory path to a file in this repo's
  working tree. The file stays writable, and git tracks it.

Many tools write their own configuration back: Zed's settings UI, Claude Code's `/config`,
`/theme` and plugin toggles, herdr's onboarding and theme picker, LazyVim's `lazy-lock.json` and
`lazyvim.json`. A read-only store file rejects that write. Claude Code then left
`settings.json.backup` files behind on every switch, and the change made in the app was lost.

Some home-directory folders mix sources. Claude Code's `skills/` holds skills from the Nix store
(`ast-grep`), links into `~/.agents/skills`, and plugin folders. A link that replaces the whole
folder hides all the others.

Some files hold state or secrets: `~/.claude.json` holds OAuth and session state, and `bw`'s
`data.json` holds refresh tokens and the encrypted vault.

The modules already follow one rule for these cases, but only their comments state it, one module
at a time (`claude-code/default.nix`, `zed/default.nix`, `herdr/default.nix`,
`agents/default.nix`). A new module has no single place to learn the rule from.

## Decision

Place each tool's configuration by what the tool does with it:

| The tool…                              | Use                                                              |
| -------------------------------------- | ---------------------------------------------------------------- |
| never writes its configuration         | a native Home Manager option                                     |
| writes its configuration back          | `mkOutOfStoreSymlink` to a tracked file under `dotfilesPath`     |
| shares a folder with other sources     | one link per item, never a link that replaces the whole folder   |
| keeps state or secrets in a file       | nothing: the file is never tracked                               |

- A native option is the default. It is reproducible and needs no checkout.
- A module that uses `mkOutOfStoreSymlink` names the tool's write-back in a comment. Its targets
  live next to the module, under `modules/features/<feature>/`, and the module reaches them through
  `config.dotfiles.user.dotfilesPath`.
- A module that takes the second row opts out of the native option for the same file. For example,
  `claude-code/default.nix` leaves `programs.claude-code.settings` unset, because the module writes
  `settings.json` into the store as soon as that option is non-empty.
- A whole-folder link is fine when the folder has one source: `neovim/nvim`, the `rules/`,
  `commands/` and `hooks/` folders of Claude Code.

## Consequences

### Positive

- A tool's own write survives the next switch, and `git status` shows it as a change to commit or
  to revert.
- No `.backup` churn from a tool that writes to a read-only file.
- A new module has one rule to follow, and a reviewer has one rule to check.

### Negative

- An out-of-store target depends on the checkout at `dotfilesPath`. A moved or missing checkout
  breaks the links until the next switch with the new path.
- A writable target is not reproducible from the flake alone: its content is whatever the working
  tree holds, committed or not.
- An app can write content the owner did not review into a tracked file. It shows up in
  `git status`, but it lands nowhere unless committed.

### Neutral

- `nushell/default.nix` uses `mkOutOfStoreSymlink` for another purpose: it points nu's macOS default
  folder at `programs.nushell.configDir`, which is a link between two home paths, not into the repo
  (ADR-008). This ADR does not cover that use.
- Secrets stay out of the repo by the fourth row. ADR-006 covers SSH keys, and
  `bitwarden/default.nix` the `bw` vault.

## Alternatives Considered

### Native options everywhere

Rejected. Every tool that writes back breaks or leaves `.backup` files, and every change made in
the app is lost on the next switch.

### Copy on activation

An activation script copies a template from the repo into the home directory when the file is
missing. Rejected: the copy is writable, but its changes never flow back into git, and the template
drifts from the file in use.

### `mkOutOfStoreSymlink` everywhere

Rejected. A file the tool never writes gains nothing from being writable, and loses the
reproducibility of a store file. It also depends on the checkout for no benefit.

## References

- `modules/features/claude-code/default.nix` — the `settings.json.backup` churn and the opt-out of
  the module's own `settings`, `rules` and `agents` options
- `modules/features/zed/default.nix`, `modules/features/herdr/default.nix`,
  `modules/features/agents/default.nix`, `modules/features/neovim/default.nix`
- [ADR-002](./002-xdg-compliance-session-variables.md) — XDG locations of the linked files
- [ADR-006](./006-1password-ssh-agent-integration.md) — SSH keys stay in 1Password
- [ADR-008](./008-nushell-login-shell.md) — the nushell config-folder link
- `infrastructure/developer` ADR 0006 — the same rule for the team repo, where a writable tracked
  file is shared by every engineer ([infrastructure/developer!3](https://dev.thingos.io/infrastructure/developer/-/merge_requests/3))
- [Home Manager: `mkOutOfStoreSymlink`](https://nix-community.github.io/home-manager/options.xhtml#opt-home.file._name_.source)
