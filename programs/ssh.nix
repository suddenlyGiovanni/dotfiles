# SSH - OpenSSH client configuration
# https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix
#
# This module manages SSH client configuration declaratively
# Note: SSH keys are managed by 1Password, not this module
_: {
  programs.ssh = {
    enable = true;

    # Opt out of default config values that will be removed in future home-manager
    # We explicitly set what we need in matchBlocks."*" below
    enableDefaultConfig = false;

    # ── Host-specific Configuration ─────────────────────────────────────────
    matchBlocks = {
      # ThingOS development server
      "dev.thingos.io" = {
        hostname = "dev.thingos.io";
        user = "git";
        identitiesOnly = true;
        identityFile = ["~/.ssh/thingos.pub"];
      };

      # Default configuration for all hosts
      # Uses 1Password SSH agent for key management
      # https://developer.1password.com/docs/ssh/get-started
      "*" = {
        extraOptions = {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };
    };
  };
}
