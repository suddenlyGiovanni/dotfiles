# 1Password - Password manager and CLI integration
# https://developer.1password.com/docs/cli/
#
# This module provides comprehensive 1Password integration:
# - 1Password CLI with XDG-compliant config directory
# - Shell plugins for biometric auth with supported CLIs (gh, aws, etc.)
# - SSH agent configuration (env var; SSH client config is in ssh.nix)
#
# Shell plugins wrap supported CLIs with `op plugin run`, enabling:
# - Biometric authentication (Touch ID) for CLI operations
# - No plaintext credentials in config files
# - Seamless credential injection
#
# Supported plugins: https://developer.1password.com/docs/cli/shell-plugins/
# Config directories: https://developer.1password.com/docs/cli/config-directories
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;

  # 1Password SSH agent socket path (macOS)
  # This is the default location for the 1Password SSH agent on macOS
  onePasswordAgentSock = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in {
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
    plugins = with pkgs; [
      gh # GitHub CLI - PR, issues, repos management
      awscli2 # AWS CLI - cloud infrastructure management
    ];
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
}
