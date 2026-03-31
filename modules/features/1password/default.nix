# 1Password - Password manager and CLI integration
# https://developer.1password.com/docs/cli/
#
# This module provides comprehensive 1Password integration:
# - 1Password CLI with XDG-compliant config directory
# - Shell plugins for biometric auth with supported CLIs (gh, aws, etc.)
# - SSH agent integration with public key management
# - SSH agent configuration (agent.toml)
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                    1Password SSH Agent Architecture                         │
# │                                                                             │
# │  ┌─────────────────────────────────────────────────────────────────────┐   │
# │  │                        1Password App                                 │   │
# │  │  - Stores private keys (never exported)                             │   │
# │  │  - SSH Agent listens on Unix socket                                 │   │
# │  │  - Prompts for Touch ID when signing requested                      │   │
# │  └──────────────────────────┬──────────────────────────────────────────┘   │
# │                             │                                               │
# │                             ▼                                               │
# │              ~/Library/Group Containers/.../agent.sock                      │
# │                             │                                               │
# │                             ▼                                               │
# │  ┌─────────────────────────────────────────────────────────────────────┐   │
# │  │                        SSH Client                                    │   │
# │  │  - Reads ~/.ssh/config for IdentityFile (public key)                │   │
# │  │  - Tells agent: "sign with THIS key" (via public key matching)      │   │
# │  │  - Never sees private key                                           │   │
# │  └─────────────────────────────────────────────────────────────────────┘   │
# │                                                                             │
# │  Key insight: IdentityFile points to PUBLIC key. SSH uses it to tell       │
# │  the agent which private key to use. This prevents "too many keys" errors. │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# Shell plugins wrap supported CLIs with `op plugin run`, enabling:
# - Biometric authentication (Touch ID) for CLI operations
# - No plaintext credentials in config files
# - Seamless credential injection
#
# Co-located files:
# - agent.toml: SSH agent configuration (which keys to expose)
#
# Related: ssh.nix (SSH client configuration)
# ADR: docs/adr/006-1password-ssh-agent-integration.md
#
# Supported plugins: https://developer.1password.com/docs/cli/shell-plugins/
# Config directories: https://developer.1password.com/docs/cli/config-directories
# SSH agent docs: https://developer.1password.com/docs/ssh/agent
_: {
  # ── Darwin: install 1Password via Homebrew ─────────────────────────────────
  flake.modules.darwin."1password" = _: {
    homebrew.casks = ["1password@beta"];
  };

  # ── Home Manager: CLI, shell plugins, SSH agent, XDG ──────────────────────
  flake.modules.homeManager."1password" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Host-specific feature flags
    # Derived from hostRole in host assembly (see options.nix, host-assembly.nix)
    inherit (config.dotfiles) isWorkHost;
    inherit (lib) mkDefault;

    # Directory containing this module and its config files
    moduleDir = ./.;

    # ── 1Password SSH Agent Socket ──────────────────────────────────────────────
    # macOS socket path for 1Password SSH agent
    # This is where 1Password listens for SSH signing requests
    onePasswordAgentSock = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

    # ── SSH Public Keys ─────────────────────────────────────────────────────────
    # Public keys from 1Password SSH keys
    #
    # These are PUBLIC keys only - private keys remain securely in 1Password.
    # SSH uses these to tell the 1Password agent which key to use for signing,
    # preventing "Too many authentication failures" when you have multiple keys.
    #
    # To add a new key:
    # 1. Create SSH key in 1Password (Ed25519 recommended)
    # 2. Copy the public key from 1Password
    # 3. Add it here with a descriptive name
    # 4. Add the key name to agent.toml (co-located in this directory)
    # 5. Add corresponding host config in ssh.nix
    # 6. Run `just switch`
    # 7. Add the public key to the remote service (GitHub, etc.)
    #
    # Format: name = "ssh-ed25519 AAAA... comment";
    # Key names must match exactly with 1Password item titles
    # Verify with: op item list --categories "SSH Key" --format=json
    sshPublicKeys = {
      # GitHub Authentication SSH Key (vault: Private)
      # Used for: github.com repositories
      github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWr93ib9vcKuQwzGW8NqPh1P2mws9qGKGp3opK99SIf GitHub Authentication SSH Key";

      # Thingos Authentication SSH Key (vault: Work - Haefele)
      # Used for: dev.thingos.io
      thingos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBn88uA0HDdb7kKZm99kWyhKOYwwVi84pP3TaNoY53W Thingos Authentication SSH Key";

      # Git Commit Signing Key (vault: Private)
      # Used for: signing commits on GitHub, GitLab, etc.
      # This key proves authorship, not authentication (separate from SSH auth keys)
      # Must be added to each Git platform as a "Signing Key" (not "Authentication Key")
      git-signing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQG9kbarRd3l6tx2X1AIS4H4Au2JhqI+j1q55W9yBM3 Git Commit Signing Key";

      # Add more keys as needed:
      # gitlab = "ssh-ed25519 AAAA... GitLab";
      # work-github = "ssh-ed25519 AAAA... Work GitHub";
    };
  in {
    config = {
      # ── Shared Options ─────────────────────────────────────────────────────────
      # Expose SSH keys and agent socket for other modules (ssh.nix, git.nix)
      # Options are declared in hm-options.nix
      dotfiles.sshKeys = sshPublicKeys;
      dotfiles.onePasswordAgentSock = onePasswordAgentSock;

      # ── Shell Plugins ───────────────────────────────────────────────────────────
      # Enable 1Password shell plugins for supported CLIs
      # This creates shell wrapper functions that use `op plugin run`
      # for biometric-authenticated credential injection
      #
      # When you run `gh pr list`, it actually executes:
      #   op plugin run -- gh pr list
      # 1Password prompts for Touch ID, injects credentials, runs the command
      programs._1password-shell-plugins = {
        enable = true;

        # List of packages to enable shell plugins for
        # Each package must have a corresponding 1Password shell plugin
        # See: https://developer.1password.com/docs/cli/shell-plugins/
        plugins = with pkgs;
          [
            gh # GitHub CLI - PR, issues, repos management
          ]
          ++ lib.optionals (!isWorkHost) [
            awscli2 # AWS CLI - only on personal (work uses SSO, see awscli.nix)
          ]
          ++ lib.optionals isWorkHost [
            glab # GitLab CLI - work only (self-hosted GitLab)
          ];
      };

      # ── Home Files ───────────────────────────────────────────────────────────────
      home.file =
        # SSH Public Key Files
        # Create ~/.ssh/*.pub files from the sshPublicKeys defined above
        #
        # These public key files serve two purposes:
        # 1. SSH client reads them to know which key to request from the agent
        # 2. Documentation - you can see which keys are configured
        #
        # The corresponding IdentityFile references are in ssh.nix
        builtins.listToAttrs (
          lib.mapAttrsToList (name: key: {
            name = ".ssh/${name}.pub";
            value = {
              text = key;
            };
          })
          sshPublicKeys
        )
        // {
          # SSH Agent Configuration
          # Co-located agent.toml controls which keys the 1Password agent exposes
          # and in what order. This prevents "Too many authentication failures" by
          # explicitly listing keys rather than exposing all keys from a vault.
          #
          # Note: 1Password uses ~/.config/1Password (capital P), not XDG_CONFIG_HOME
          ".config/1Password/ssh/agent.toml".source = "${moduleDir}/agent.toml";
        };

      # ── XDG Compliance ──────────────────────────────────────────────────────────
      # Configure 1Password CLI to use XDG-compliant config directory
      # Without this, it may create ~/.op (legacy location)
      #
      # Precedence (first match wins):
      # 1. --config flag
      # 2. OP_CONFIG_DIR env var  <-- we set this
      # 3. ~/.op (legacy)
      # 4. ${XDG_CONFIG_HOME}/.op
      # 5. ~/.config/op
      # 6. ${XDG_CONFIG_HOME}/op
      home.sessionVariables = {
        # Explicit XDG config directory for 1Password CLI
        OP_CONFIG_DIR = "${config.xdg.configHome}/op";

        # SSH agent socket for tools that need it (git, ssh, etc.)
        # Note: SSH client IdentityAgent is configured in ssh.nix
        SSH_AUTH_SOCK = mkDefault onePasswordAgentSock;
      };

      # ── Directory Creation ──────────────────────────────────────────────────────
      # Ensure the 1Password config directory exists
      home.activation.create1PasswordConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/op"
      '';
    };
  };
}
