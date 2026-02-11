# Claude Code - AI-powered coding assistant
# Uses native installation (curl installer) for automatic updates
# Home-manager only manages configuration and PATH
{config, ...}: {
  # ── XDG Compliance ──────────────────────────────────────────────────────────
  # Force Claude Code to use XDG-compliant config directory
  # Note: home-manager's programs.claude-code module uses hardcoded .claude/ paths
  # This env var overrides the default location to be XDG compliant
  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";
  };

  # ── PATH for Native Install ─────────────────────────────────────────────────
  # The native installer places the binary at ~/.local/bin/claude
  # Install with: curl -fsSL https://claude.ai/install.sh | bash
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
}
