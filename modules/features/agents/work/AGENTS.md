<!-- Source: dotfiles/modules/features/agents/work/AGENTS.md, linked as ~/Developer/work/CLAUDE.md
     and ~/Developer/work/AGENTS.md on the work host. Claude Code loads it for every repository under
     ~/Developer/work, after the personal instructions and before the repository's own. -->

# Work

Instructions for every work repository under `~/Developer/work`. A repository's own `AGENTS.md`
or `CLAUDE.md` comes after this file and wins where they differ.

## Where configuration belongs

- **This repository's conventions go in the repository**: `AGENTS.md`/`CLAUDE.md`, `.claude/`
  (settings, rules, skills, agents, hooks) and `.mcp.json`, committed, so colleagues get the same
  setup when they clone it.
- **Conventions shared by every work repository** belong to the team, in
  `infrastructure/developer` (`~/Developer/work/developer`), not in one repository and not in
  personal configuration.
- **Personal preferences never go into a work repository's committed files.** Use
  `CLAUDE.local.md` or `.claude/settings.local.json`, which stay on this machine.

## Forges and secrets

- Work repositories are on the self-hosted GitLab at `dev.thingos.io`: use `glab` for merge
  requests, issues and pipelines, not `gh`.
- Team secrets live in the company Vaultwarden (`pw.thingos.io`), read through `with-secrets` and
  a repository's `secretspec.toml`. Never write a secret to a file, a commit, or the conversation.
- An agent session has its own credentials (the agent tier): git pushes over HTTPS and commits are
  signed with the agent's key. Operations credentials (AWS, Cloudflare tokens, deploys) are the
  user's alone: ask for those steps, do not look for a way around them.
