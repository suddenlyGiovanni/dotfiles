---
paths:
  - 'modules/features/git/**'
  - 'modules/features/1password/**'
  - 'modules/features/ssh.nix'
---

# Git signing and SSH

- **1Password signs commits and holds the SSH keys** ([ADR-006](../../docs/adr/006-1password-ssh-agent-integration.md)).
  Git signs with `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`. Add an SSH key in
  `1password/default.nix`, in both `sshPublicKeys` and `agent.toml`.
- **The user's keys need the user**. The 1Password agent prompts for each signature and each SSH
  connection, so a run with no user present cannot use them. Do not change the user's git
  configuration to work around this.
- **Agent sessions have their own tier** (`modules/features/agent-tier/`,
  [runbook](../../docs/AGENT-TIER.md)). `agent-tier-check` says what a machine still needs. A
  harness sources
  `~/.config/agent-tier/env.sh` before each command. git then reads
  `~/.config/git/agent.gitconfig`: HTTPS with the CLI's credential helper, commits signed with
  `~/.ssh/agent-signing`, no SSH. Change the tier in that module, never in `git/default.nix`.
  Where the tier is not active (`AGENT_TIER` is unset), the user's global agent instructions give
  the override for each command.
