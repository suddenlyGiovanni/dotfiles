# Claude Code - AI-powered coding assistant
# https://docs.anthropic.com/en/docs/claude-code
#
# Uses native installation (curl installer) for automatic updates.
# Home-manager only manages XDG-compliant config directory placement
# via CLAUDE_CONFIG_DIR environment variable.
_: {
  flake.modules.homeManager.claude-code = {config, ...}: {
    # ── XDG Compliance ──────────────────────────────────────────────────────────
    # Force Claude Code to use XDG-compliant config directory
    # Note: home-manager's programs.claude-code module uses hardcoded .claude/ paths
    # This env var overrides the default location to be XDG compliant
    home.sessionVariables = {
      CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";
    };

    # Note: The native installer places the binary at ~/.local/bin/claude
    # PATH for ~/.local/bin is managed globally in home.nix
  };
}
