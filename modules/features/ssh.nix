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
_: {
  flake.modules.homeManager.ssh = {
    config,
    lib,
    ...
  }: let
    # Read from shared options (set by 1password module in hm-options.nix)
    onePasswordAgentSock = config.dotfiles.onePasswordAgentSock;
    inherit (config.dotfiles) isWorkHost;

    # ── Work servers (cloud/infrastructure) ─────────────────────────────────────
    # The team keeps the admin aliases (`admin_deploy_1`, …) in that repository's
    # `ssh/config`, and one public key per server in `ssh/keys/`. The private keys
    # live in the company Bitwarden and are served by the Bitwarden desktop SSH
    # agent, which the aliases select themselves (IdentityAgent), so they do not
    # fall through to the 1Password agent of the `*` block.
    #
    # This is the declarative form of that repository's `ssh/setup.sh`:
    # the Include replaces "merge ssh/config by hand", the symlinks replace the
    # copy of the public keys into ~/.ssh. Both point into the checkout, so a
    # `git pull` there is enough to pick up a new server. Nothing breaks when the
    # checkout is missing: ssh skips a missing Include and a dangling key link.
    infraRepo = "${config.home.homeDirectory}/Developer/work/cloud/infrastructure";

    # File names in `ssh/keys/` without `.pub`. Listed by hand because a flake
    # cannot read a directory outside the store. Add a name when the repository
    # adds a server.
    infraServerKeys = [
      "id_ed25519_admin_analytics_1"
      "id_ed25519_admin_build_1"
      "id_ed25519_admin_control_1"
      "id_ed25519_admin_control_2"
      "id_ed25519_admin_control_3"
      "id_ed25519_admin_deploy_1"
      "id_ed25519_admin_dev_1"
      "id_ed25519_admin_dev_2_new"
      "id_ed25519_admin_dev_3"
      "id_ed25519_admin_gitlab"
      "id_ed25519_admin_production_1"
      "id_ed25519_admin_production_2"
      "id_ed25519_admin_production_3"
      "id_ed25519_admin_production_4"
      "id_ed25519_admin_production_6"
      "id_ed25519_admin_tools_1"
      "id_ed25519_hoh_connect_hub"
    ];
  in {
    home.file = lib.mkIf isWorkHost (lib.listToAttrs (map (name:
      lib.nameValuePair ".ssh/${name}.pub" {
        source = config.lib.file.mkOutOfStoreSymlink "${infraRepo}/ssh/keys/${name}.pub";
      })
    infraServerKeys));

    programs.ssh = {
      enable = true;

      # Opt out of default config values that will be removed in future home-manager.
      # We explicitly set what we need in `settings` below.
      enableDefaultConfig = false;

      # home-manager writes `Include` at the top of the file, before every Host
      # block. ssh takes the first value it finds, so the aliases keep their own
      # agent and key. See `infraRepo` above.
      includes = lib.optionals isWorkHost ["${infraRepo}/ssh/config"];

      # ── Host-specific Configuration ─────────────────────────────────────────────
      # Each host block specifies which SSH key to use via IdentityFile.
      # The IdentityFile points to a PUBLIC key — SSH uses this to tell the
      # 1Password agent which private key to use for signing.
      #
      # Directive names match OpenSSH ssh_config(5) exactly (PascalCase).
      # Booleans are rendered as yes/no; lists become repeated directives.
      settings = {
        # ── GitHub ──────────────────────────────────────────────────────────────
        # Personal GitHub account
        # Public key managed in 1password.nix (sshPublicKeys.github)
        "github.com" = {
          HostName = "github.com";
          User = "git";
          # Point to PUBLIC key - SSH uses this to identify which key to request
          # from the 1Password agent. The private key never leaves 1Password.
          IdentityFile = ["~/.ssh/github.pub"];
          # Only use the specified identity, don't try other keys
          # This prevents "Too many authentication failures" errors
          IdentitiesOnly = true;
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };

        # ── ThingOS Development Server ──────────────────────────────────────────
        # Work-related development server
        # Public key managed in 1password.nix (sshPublicKeys.thingos)
        "dev.thingos.io" = {
          HostName = "dev.thingos.io";
          User = "git";
          IdentityFile = ["~/.ssh/thingos.pub"];
          IdentitiesOnly = true;
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };

        # ── Default Configuration ───────────────────────────────────────────────
        # Fallback for any host not explicitly configured above.
        # Uses 1Password SSH agent for key management. Specific hosts above
        # override this with their own IdentityFile.
        "*" = {
          IdentityAgent = "\"${onePasswordAgentSock}\"";
        };
      };
    };
  };
}
