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
- **Unattended runs cannot sign**. The 1Password agent prompts the user for each signature, so a run
  with no user present cannot sign or push over SSH. Do not change the git configuration to work
  around this. The user's global agent instructions give the override for each command.
