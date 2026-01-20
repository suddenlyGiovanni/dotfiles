# ADR-006: 1Password SSH Agent Integration

## Status

Accepted

## Date

2026-01-20

## Context

We use 1Password as our password manager and want to leverage its SSH agent functionality for:

1. **Secure key storage**: Private keys never leave 1Password's encrypted vault
2. **Biometric authentication**: Touch ID prompts for SSH operations
3. **Cross-device sync**: Same SSH keys available on all machines via 1Password sync
4. **Simplified key management**: No manual key file management or passphrases

### How the 1Password SSH Agent Works

The 1Password SSH agent operates as a bridge between SSH clients and your encrypted keys:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        1Password App                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      SSH Agent                               ││
│  │  - Stores private keys (never exported)                     ││
│  │  - Listens on Unix socket for signing requests              ││
│  │  - Prompts for biometric auth (Touch ID) when needed        ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                              ▼                                   │
│           ~/Library/Group Containers/.../agent.sock              │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SSH Client                                │
│  - Connects via SSH_AUTH_SOCK or IdentityAgent config           │
│  - Sends challenge: "sign this data with key X"                 │
│  - Receives signature (never sees private key)                  │
└─────────────────────────────────────────────────────────────────┘
```

### The "Too Many Keys" Problem

SSH agents offer keys sequentially until a server accepts one. OpenSSH servers default to 6
authentication attempts before disconnecting. With multiple SSH keys in 1Password, you can hit
this limit and see "Too many authentication failures."

### The Solution: IdentityFile with Public Keys

The `IdentityFile` directive in SSH config can point to a **public key** file. SSH reads this
public key and tells the agent exactly which private key to use for signing. This prevents the
agent from trying all available keys.

```text
~/.ssh/config                          ~/.ssh/github.pub
┌────────────────────────────┐         ┌──────────────────────────┐
│ Host github.com            │         │ ssh-ed25519 AAAA...      │
│   IdentityFile ~/.ssh/     │────────▶│ (public key only)        │
│              github.pub    │         └──────────────────────────┘
│   IdentityAgent ~/../sock  │                    │
└────────────────────────────┘                    │
                                                  ▼
                                    1Password agent matches public key
                                    to stored private key, signs request
```

**Key insight**: The `IdentityFile` points to a **public key**, not a private key. The private key
remains safely in 1Password.

## Decision

We implement a declarative 1Password SSH agent integration using home-manager with these components:

### 1. Configuration Layers

| Layer | File | Purpose | Managed By |
|-------|------|---------|------------|
| SSH client config | `~/.ssh/config` | Host-specific key selection | `programs.ssh` in `ssh.nix` |
| Public key files | `~/.ssh/*.pub` | Tell SSH which key to request | `home.file` in `1password.nix` |
| Agent config | `~/.config/1Password/ssh/agent.toml` | Key ordering (optional) | `home.file` in `1password.nix` |
| Environment | `SSH_AUTH_SOCK` | Agent socket location | `home.sessionVariables` in `1password.nix` |

### 2. Module Responsibilities

**`programs/1password.nix`**:
- Define SSH public keys as Nix values (for documentation and single source of truth)
- Create `~/.ssh/*.pub` files via `home.file`
- Optionally create `~/.config/1Password/ssh/agent.toml` for key ordering
- Set `SSH_AUTH_SOCK` environment variable
- Configure 1Password shell plugins (gh, awscli2)

**`programs/ssh.nix`**:
- Configure `IdentityAgent` to use 1Password socket
- Define host-specific `IdentityFile` references to public keys
- Set `IdentitiesOnly yes` to prevent offering other keys

### 3. Public Key Management Pattern

Public keys are stored as Nix string values in `1password.nix`:

```nix
let
  # SSH public keys from 1Password
  # These are PUBLIC keys only - private keys remain in 1Password
  sshPublicKeys = {
    github = "ssh-ed25519 AAAA... GitHub";
    # Add more keys as needed:
    # gitlab = "ssh-ed25519 AAAA... GitLab";
    # work = "ssh-ed25519 AAAA... Work";
  };
in {
  # Create public key files in ~/.ssh/
  home.file = lib.mapAttrs' (name: key: {
    name = ".ssh/${name}.pub";
    value = {
      text = key;
      # Restrictive permissions for SSH compatibility
    };
  }) sshPublicKeys;
}
```

Benefits:
- **Single source of truth**: Keys defined once, used by both file creation and documentation
- **Declarative**: Adding a new key is just adding an attribute
- **Discoverable**: All keys visible in one place
- **Version controlled**: Key changes are tracked in git (public keys are safe to commit)

### 4. SSH Config Integration

In `ssh.nix`, reference the public key files:

```nix
programs.ssh.matchBlocks = {
  "github.com" = {
    hostname = "github.com";
    user = "git";
    identityFile = ["~/.ssh/github.pub"];
    identitiesOnly = true;
    extraOptions = {
      IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
    };
  };
};
```

## Consequences

### Positive

- **Secure**: Private keys never leave 1Password
- **Declarative**: All SSH configuration is Nix-managed and reproducible
- **Scalable**: Easy to add new hosts/keys without hitting authentication limits
- **Cross-device**: Same configuration works on all machines (1Password syncs keys)
- **Documented**: Public keys in Nix serve as living documentation
- **Biometric**: Touch ID for SSH operations

### Negative

- **1Password dependency**: Requires 1Password app running with SSH agent enabled
- **Manual key export**: Public keys must be manually copied from 1Password once
- **macOS-specific socket path**: Socket path differs on Linux (would need conditional)

### Neutral

- Public keys are committed to git (this is safe and intended)
- Requires initial 1Password setup (one-time)

## Alternatives Considered

### 1. Use 1Password CLI to Fetch Keys

Dynamically fetch public keys using `op read` during activation.

**Rejected because**: Adds runtime dependency on 1Password CLI being authenticated, complicates
activation, and introduces potential failures during `darwin-rebuild switch`.

### 2. Store Private Keys in Nix

Use agenix or sops-nix to manage encrypted private keys.

**Rejected because**: Adds complexity, requires separate secret management infrastructure, and
defeats the purpose of using 1Password which already handles this well.

### 3. No IdentityFile Configuration

Rely on 1Password's `agent.toml` for key ordering instead.

**Rejected because**: SSH config is more standard, works with all SSH clients, and provides
host-specific control that `agent.toml` cannot.

### 4. Symlink to 1Password's Key Files

1Password can export public keys to `~/.ssh/` automatically.

**Rejected because**: Less control over file locations/names, depends on 1Password's behavior
which may change, and isn't declaratively managed.

## Implementation Notes

### Adding a New SSH Key

1. Create SSH key in 1Password (Ed25519 recommended)
2. Copy public key from 1Password
3. Add to `sshPublicKeys` in `1password.nix`
4. Add host configuration in `ssh.nix` referencing the key
5. Run `just switch`
6. Add public key to the remote service (GitHub, GitLab, etc.)

### Verifying Configuration

```bash
# Check SSH can connect
ssh -T git@github.com

# Verbose output to see key selection
ssh -vT git@github.com 2>&1 | grep -E "(Offering|identity|IdentityFile)"

# List keys available in agent
ssh-add -L
```

### Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Permission denied (publickey)" | Key not in agent or not added to GitHub | Check 1Password SSH agent is enabled; verify key added to GitHub |
| "Too many authentication failures" | Too many keys, no IdentityFile | Add `identityFile` and `identitiesOnly = true` to SSH config |
| "Agent refused operation" | 1Password locked or agent disabled | Unlock 1Password, enable SSH agent in Settings > Developer |

## References

- [1Password SSH Agent Documentation](https://developer.1password.com/docs/ssh/agent)
- [1Password SSH Agent Configuration](https://developer.1password.com/docs/ssh/agent/config)
- [1Password Multiple Git Identities](https://developer.1password.com/docs/ssh/agent/advanced#use-multiple-git-identities-on-the-same-machine)
- [Home-Manager SSH Module](https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix)
- [OpenSSH IdentityFile Documentation](https://man.openbsd.org/ssh_config#IdentityFile)
