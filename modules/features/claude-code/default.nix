# Claude Code - AI-powered coding assistant
# https://docs.anthropic.com/en/docs/claude-code
#
# Uses native installation (curl installer) for automatic updates.
# The home-manager `programs.claude-code` module is used purely for declarative
# configuration; package management is opted out via `package = null` so the
# curl-installed binary at ~/.local/bin/claude keeps owning updates.
{
  inputs,
  config,
  ...
}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
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
      # Surgical per-skill installs (attrset mode, NOT path mode — path mode
      # would clobber sibling user-managed skills under ${configDir}/skills/).
      skills = {
        # Official ast-grep skill: routes structural code search through `sg`
        # instead of `rg` when the question is syntactic. Source pinned via
        # flake input `ast-grep-agent-skill`.
        ast-grep = "${inputs.ast-grep-agent-skill}/ast-grep/skills/ast-grep";
      };
      # NOTE: `settings` is intentionally left unset. The upstream module only
      # writes ${configDir}/settings.json when `settings` or `marketplaces` is
      # non-empty, and it writes it as a *read-only* nix-store symlink — which
      # Claude Code cannot write back to (theme/effort/plugin toggles, etc.),
      # spawning settings.json.backup churn. We opt out here and own the file
      # ourselves via an out-of-store symlink below (Zed pattern), so it stays
      # editable in place and Claude's own writes land in the dotfiles tree.
    };

    # ── settings.json: editable, SVC-tracked (Zed pattern) ────────────────────
    # mkOutOfStoreSymlink keeps the file writable in place at
    # ${configDir}/settings.json -> repo, so interactive changes Claude makes
    # land in the working tree to be committed. configDir resolves to
    # ${xdg.configHome}/claude, matching the path the upstream module would use,
    # so CLAUDE_CONFIG_DIR (auto-exported by `configDir`) keeps pointing here.
    xdg.configFile."claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/claude-code/settings.json";

    # Note: The native installer places the binary at ~/.local/bin/claude
    # PATH for ~/.local/bin is managed globally in home.nix
  };
}
