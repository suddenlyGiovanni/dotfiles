# `.agents/` — what every agent harness shares

This folder is the harness-neutral root for agent tooling in this repo. Anything here works the same
whichever coding agent (Claude Code, OpenCode, …) is driving, so switching harnesses means wiring
the new one to these folders, not rewriting them. A harness folder (`.claude/`, `.opencode/`) keeps
only what is in that harness's own format.

| Path         | Holds                                                                                                                                                                                    | Reached by                                                                         |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `../AGENTS.md` | the project instructions                                                                                                                                                               | read natively; Claude Code reads `CLAUDE.md`, a symlink to it                      |
| `rules/`     | short rules that fire on a path: Markdown with a `paths:` glob list in the frontmatter                                                                                                   | `.claude/rules` → `rules/` (one directory symlink)                                 |
| `skills/`    | project skills: `<name>/SKILL.md`, with `name` and `description` frontmatter                                                                                                             | OpenCode reads it natively; Claude Code through `.claude/skills/<name>` → `../../.agents/skills/<name>`, one link per skill |
| `agents/`    | subagent definitions: Markdown with `name` and `description` frontmatter; harness extras (`tools`, `model`) may follow                                                                   | `.claude/agents` → `agents/` (one directory symlink)                               |
| `mcpls.toml` | the MCP-to-LSP bridge with every language server in the devshell, for a harness that has no LSP client of its own                                                                         | `.opencode/opencode.jsonc`                                                         |

Claude Code links each skill on its own, not the whole folder, so that `.claude/skills/` can also
hold a skill that only makes sense under Claude. Add a shared skill with:

```bash
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

## What stays harness-specific

- **Hooks** (`.claude/hooks/`, wired in `.claude/settings.json`): their input and output are
  Claude Code's hook protocol. A harness without hooks gets the same guarantees from the gates the
  hooks call (`just check`, the git hooks), which [AGENTS.md](../AGENTS.md) tells every agent to
  run.
- **LSP wiring** (`.claude/plugins/dotfiles-lsp`): Claude Code's plugin format. Its server list
  matches the `lsp` key in `.opencode/opencode.jsonc` and the servers in `mcpls.toml`; change them
  together.
- **Claude's mcpls subset** (`.claude/mcpls.toml`): Claude Code's LSP tool already serves most
  routes, so its bridge carries only what that tool lacks.

## Adding a harness

Point it at `../AGENTS.md`, `skills/`, `rules/` and `agents/` with symlinks or its own config
keys, give it `.mcp.json`'s servers in its MCP format, and note in AGENTS.md which hooks it does
not run.
