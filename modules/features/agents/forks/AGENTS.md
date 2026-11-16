<!-- Source: dotfiles/modules/features/agents/forks/AGENTS.md, linked as ~/Developer/forks/AGENTS.md,
     with CLAUDE.md beside it linking to that. Claude Code loads it for every repository under
     ~/Developer/forks, after the personal instructions and before the repository's own. -->

# Forks

Every repository under `~/Developer/forks` is someone else's project: a fork to contribute to, or a
clone to read. The project's own `AGENTS.md`, `CONTRIBUTING` and tooling set its conventions, and
they win over the personal instructions where the two differ.

## Remotes

- Remote names differ between repositories: `origin` is the user's fork in some and the original
  project in others. Read `git remote -v` before every push, and push only to a remote under
  `github.com/suddenlyGiovanni`.
- A contribution goes back as a pull request from a branch on the user's fork to the original
  project.
- A clone with no remote under the user's account is for reading and running; change it only when
  the user asks.

## Commits

- Follow the project's commit format, changeset tooling and sign-off or CLA rules; read them before
  the first commit on a branch.
- Personal configuration goes in `CLAUDE.local.md`, `.claude/settings.local.json` or
  `.git/info/exclude`, which stay on this machine; the committed files carry only the project's
  conventions.
