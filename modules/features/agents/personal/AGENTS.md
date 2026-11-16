<!-- Source: dotfiles/modules/features/agents/personal/AGENTS.md, linked as
     ~/Developer/personal/AGENTS.md, with CLAUDE.md beside it linking to that. Claude Code loads it
     for every repository under ~/Developer/personal, after the personal instructions and before the
     repository's own. The dotfiles live outside this folder and do not get it. -->

# Personal projects

Every repository under `~/Developer/personal` is the user's own project.

- The user's preferences are the project's conventions. Agent configuration (`AGENTS.md`,
  `CLAUDE.md`, `.claude/`, `.mcp.json`) belongs in the committed files, so every machine gets it.
- A repository with no remote lives only on this machine, and some hold private records. Keep their
  contents here: add a remote, publish, or send their files to an outside service only when the
  user asks.
