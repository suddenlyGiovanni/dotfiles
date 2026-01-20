# SSH - OpenSSH client configuration
# https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix
#
# This module manages SSH client configuration declaratively.
# SSH keys are managed by 1Password - this module only references public keys.
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                         SSH + 1Password Integration                         │
# │                                                                             │
# │  ~/.ssh/config (this module)          ~/.ssh/*.pub (from 1password.nix)     │
# │  ┌─────────────────────────┐          ┌─────────────────────────┐          │
# │  │ Host github.com         │          │ ssh-ed25519 AAAA...     │          │
# │  │   IdentityFile ~/.ssh/  │─────────▶│ (public key)            │          │
# │  │            github.pub   │          └─────────────────────────┘          │
# │  │   IdentityAgent ~/...   │                     │                          │
# │  └─────────────────────────┘                     │                          │
# │                                                  ▼                          │
# │                                    1Password agent matches public           │
# │                                    key to private key, signs request        │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# Related: 1password.nix (public key files, SSH_AUTH_SOCK)
# ADR: docs/adr/006-1password-ssh-agent-integration.md
_: let
  # 1Password SSH agent socket path (macOS)
  # Must match the path in 1password.nix
  onePasswordAgentSock = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in {
  programs.ssh = {
    enable = true;

    # Opt out of default config values that will be removed in future home-manager
    # We explicitly set what we need in matchBlocks below
    enableDefaultConfig = false;

    # ── Host-specific Configuration ─────────────────────────────────────────────
    # Each host block specifies which SSH key to use via IdentityFile
    # The IdentityFile points to a PUBLIC key - SSH uses this to tell the
    # 1Password agent which private key to use for signing
    matchBlocks = {
      # ── GitHub ──────────────────────────────────────────────────────────────
      # Personal GitHub account
      # Public key managed in 1password.nix (sshPublicKeys.github)
      "github.com" = {
        hostname = "github.com";
        user = "git";
        # Point to PUBLIC key - SSH uses this to identify which key to request
        # from the 1Password agent. The private key never leaves 1Password.
        identityFile = ["~/.ssh/github.pub"];
        # Only use the specified identity, don't try other keys
        # This prevents "Too many authentication failures" errors
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };
      };

      # ── ThingOS Development Server ──────────────────────────────────────────
      # Work-related development server
      # Public key managed in 1password.nix (sshPublicKeys.thingos)
      "dev.thingos.io" = {
        hostname = "dev.thingos.io";
        user = "git";
        identityFile = ["~/.ssh/thingos.pub"];
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };
      };

      # ── Default Configuration ───────────────────────────────────────────────
      # Fallback for any host not explicitly configured above
      # Uses 1Password SSH agent for key management
      "*" = {
        extraOptions = {
          # Use 1Password SSH agent for all connections
          # Individual hosts above can override with specific IdentityFile
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };
      };
    };
  };
}
