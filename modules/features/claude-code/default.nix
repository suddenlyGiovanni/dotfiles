# Claude Code - AI-powered coding assistant
# https://docs.anthropic.com/en/docs/claude-code
#
# Uses native installation (curl installer) for automatic updates.
# The home-manager `programs.claude-code` module is used purely for declarative
# configuration; package management is opted out via `package = null` so the
# curl-installed binary at ~/.local/bin/claude keeps owning updates.
_: {
  flake.modules.homeManager.claude-code = {config, ...}: {
    programs.claude-code = {
      enable = true;
      # Keep the native (curl-installed) binary; don't add a nixpkgs claude-code.
      package = null;
      # XDG-compliant config dir. When this differs from the upstream default
      # (~/.claude), home-manager auto-exports CLAUDE_CONFIG_DIR for us.
      configDir = "${config.xdg.configHome}/claude";
      # Global instructions applied to every Claude Code session on this
      # machine. Written to ${configDir}/CLAUDE.md as a nix-store symlink.
      context = ./CLAUDE.md;
    };

    # Note: The native installer places the binary at ~/.local/bin/claude
    # PATH for ~/.local/bin is managed globally in home.nix
  };
}
