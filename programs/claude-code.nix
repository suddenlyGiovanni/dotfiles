# Claude Code - AI-powered coding assistant
# This module installs Claude Code and configures XDG-compliant paths
{
  config,
  pkgs,
  ...
}: {
  # ── XDG Compliance ──────────────────────────────────────────────────────────
  # Force Claude Code to use XDG-compliant config directory
  # Note: home-manager's programs.claude-code module uses hardcoded .claude/ paths
  # This env var overrides the default location to be XDG compliant
  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";
  };

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    claude-code # Claude AI-powered code editor
  ];
}
