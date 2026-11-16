# Where Claude keeps its files on this Mac

Date: 2026-11-16. Claude Code 2.1.322 (terminal, native install) and 2.1.325 (bundled in the
desktop app). Sources: the Claude Code docs (code.claude.com/docs: claude-directory, env-vars,
settings, desktop, mcp, authentication) and the files on disk.

## Three worlds

| World | Where | Read by | Tracked |
|---|---|---|---|
| Claude Code configuration | `CLAUDE_CONFIG_DIR=~/.config/claude` (shells and launchd) | the terminal CLI and the desktop app's Code tab | settings, keybindings, CLAUDE.md, rules, hooks, commands, output styles, themes, workflows, skills, the `hey` MCP server (the `hm` plugin): `modules/features/claude-code/` and the modules named in its header |
| The desktop app's own data | `~/Library/Application Support/Claude/` | the desktop app | no |
| Account-synced | claude.ai | Cowork's skills, plugins and connectors; the Code tab's account settings (branch prefix, auto-archive) | not local |

The CLI and the Code tab share one configuration: the docs say they "all read the same settings
files", and `CLAUDE_CONFIG_DIR` moves `.claude.json` with the rest. A preference the Code tab
writes, such as the output style, lands in the tracked `settings.json` through its link.

## Inside `~/.config/claude`

- **Configuration, tracked**: the links listed above.
- **Configuration, not tracked**: `.claude.json` holds personal MCP servers (none now), per-project
  trust, UI choices and account state together. Claude rewrites it whole, so it cannot be a link.
- **State**: `projects/` (transcripts, 4.2 GB), `history.jsonl`, `file-history/`, `session-env/`,
  `backups/`, `jobs/`, `daemon/`, `plans/`. Cleaned up after `cleanupPeriodDays` (30 by default),
  except `history.jsonl`.
- **Plugins**: `plugins/` (227 MB). `CLAUDE_CODE_PLUGIN_CACHE_DIR` can move it out; not done.

The native install itself is XDG: versions in `~/.local/share/claude/versions`, the link in
`~/.local/bin/claude`, staging in `~/.cache/claude`, locks in `~/.local/state/claude`. It updates
itself when the terminal CLI runs (`autoUpdatesProtectedForNative`).

## Why the state stays in the config folder

- No supported split: `CLAUDE_CONFIG_DIR` is one directory. anthropics/claude-code#1455 (XDG) is
  open; a maintainer shipped partial XDG support in 1.0.28 and removed it in 1.0.31 after reports
  of re-authentication.
- The macOS Keychain entry is keyed to the config directory: moving `CLAUDE_CONFIG_DIR` means
  signing in again, in every client that sees the new path.

## The desktop app

- `claude_desktop_config.json`: the app's preferences (launch, menu bar, Cowork browser,
  keep-awake, folder grants per device) and `mcpServers` for the chat app (none here). The app
  rewrites it; its paths are not documented.
- `claude-code/<version>`: the bundled Claude Code, separate from the terminal's.
- `claude-code-sessions/`, `git-worktrees.json`, `local-agent-mode-sessions/`: Code tab and Cowork
  session state. Cowork's files folder is `~/Claude`.
- Logs in `~/Library/Logs/Claude`, caches in `~/Library/Caches/com.anthropic.claudefordesktop`;
  the CLI's MCP logs in `~/Library/Caches/claude-cli-nodejs`.

## Done on 2026-11-16

- `~/.claude` and `~/.claude.json`, last written on 2026-11-02 by a client that started without
  `CLAUDE_CONFIG_DIR`, held nothing the live configuration lacked; moved to the Trash. The
  `env.nu` probe fix keeps the desktop app on `CLAUDE_CONFIG_DIR` from the start.
- The user-scope `cloudflare` MCP server (`mcp.cloudflare.com`, never authorised) was removed from
  `.claude.json`. Cloudflare stays a claude.ai connector ("Cloudflare Developer Platform"), which
  reaches every Claude surface.

## The layers, and where each kind of configuration goes

Claude Code has these layers, highest first: managed (`/Library/Application
Support/ClaudeCode/managed-settings.json` and `managed-settings.d/`, settings only, not
overridable), local (`.claude/settings.local.json`, `CLAUDE.local.md`), project (`.claude/`,
`.mcp.json`, `CLAUDE.md`), user (`CLAUDE_CONFIG_DIR`). Settings are read only from the project
root and the user folder. `CLAUDE.md` is the one file read from every folder above the working
directory as well, concatenated from the root down. Plugins carry skills, agents, hooks, MCP and
LSP servers and output styles, and are enabled at user or project scope.

Decided on 2026-11-16 ([TASKS.md](../TASKS.md), Planned):

| Kind | Home |
|---|---|
| Personal, every machine | the user layer, from these dotfiles, in Claude Code's own formats; skills and MCP servers as plugins of the `suddenlygiovanni-dotfiles` marketplace |
| Remote MCP servers with OAuth | claude.ai connectors, on the account |
| Work, every work repository | a team plugin marketplace in `infrastructure/developer`; meanwhile `~/Developer/work/CLAUDE.md` (from `modules/features/agents/work/AGENTS.md`, work host only) |
| Forks and clones of other projects | `~/Developer/forks/CLAUDE.md` (from `modules/features/agents/forks/AGENTS.md`, every host) |
| Work, one repository | that repository's `.claude/`, `.mcp.json` and `CLAUDE.md`, committed |
| Personal, one work repository | `CLAUDE.local.md`, `.claude/settings.local.json` |

## Open

- Tracking the desktop app's preferences, the way `rex-settings-capture` does for Rex: possible,
  but the file mixes preferences with per-device grants and is undocumented.
- `CLAUDE_CODE_PLUGIN_CACHE_DIR=~/.local/share/claude/plugins`: the one documented XDG move.
