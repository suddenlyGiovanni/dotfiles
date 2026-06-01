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

    # ── Editable, SVC-tracked config (Zed pattern) ────────────────────────────
    # mkOutOfStoreSymlink keeps each target writable in place under the repo, so
    # changes land in the dotfiles working tree to be committed — whether you
    # make them by hand or Claude does interactively (/config, /keybindings,
    # /theme, /memory, saving a /workflows run, …). We deliberately bypass the
    # upstream module's own settings/rules/agents/commands/outputStyles options:
    # those render read-only nix-store copies, which defeats in-place editing
    # (and which Claude can't write back to — that was the settings.json.backup
    # churn). configDir resolves to ${xdg.configHome}/claude, the same path the
    # module uses, so CLAUDE_CONFIG_DIR (auto-exported by `configDir`) keeps
    # pointing here.
    #
    # Directories are tracked while empty via a .gitkeep that Claude ignores
    # (rules/agents/output-styles load *.md, workflows *.js, themes *.json).
    #
    # NOT symlinked, on purpose:
    #   - commands/  : plugins (e.g. plannotator) write into it; whole-dir
    #                  symlinking would capture their droppings. Use skills/
    #                  (already tracked via the agent-skills module) instead.
    #   - hooks / statusLine : these are keys inside settings.json (tracked).
    #   - .mcp.json  : project-scoped, not a ~/.claude file. Personal/global MCP
    #                  servers live in ~/.claude.json, which holds OAuth/session
    #                  state and must never be committed.
    #   - skills/    : owned by the agent-skills module + programs.claude-code.
    xdg.configFile = let
      svc = path:
        config.lib.file.mkOutOfStoreSymlink
        "${dotfilesPath}/modules/features/claude-code/${path}";
    in {
      "claude/settings.json".source = svc "settings.json";
      "claude/keybindings.json".source = svc "keybindings.json";
      "claude/rules".source = svc "rules";
      "claude/agents".source = svc "agents";
      "claude/output-styles".source = svc "output-styles";
      "claude/workflows".source = svc "workflows";
      "claude/themes".source = svc "themes";
    };

    # Note: The native installer places the binary at ~/.local/bin/claude
    # PATH for ~/.local/bin is managed globally in home.nix
  };
}
