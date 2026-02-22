# AWS CLI - XDG configuration
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
#
# Note: The awscli2 package is installed via 1password.nix shell plugins
# for biometric-authenticated credential management.
# This module only configures XDG-compliant paths.
_: {
  flake.modules.homeManager.awscli = {config, ...}: {
    # ── XDG Compliance ──────────────────────────────────────────────────────────
    # Move AWS config and credentials to XDG directories
    # Default locations would be ~/.aws/config and ~/.aws/credentials
    home.sessionVariables = {
      AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
      AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
    };
  };
}
