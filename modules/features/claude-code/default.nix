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
    # (rules/agents/output-styles/commands load *.md, workflows *.js, themes
    # *.json; hooks/ just stores scripts referenced from settings.json).
    #
    # On commands/: plugins (e.g. plannotator) serve their own commands from
    # the plugin cache, NOT from here — verified by stale ~7-week-old orphan
    # copies the plugin never refreshed. So owning this dir is safe; it holds
    # only your personal commands.
    #
    # On hooks/: settings.json's `hooks` KEY declares when/what to run; this
    # dir is where the scripts those commands invoke live (stable path).
    #
    # NOT symlinked, on purpose:
    #   - statusLine : a key inside settings.json (already tracked).
    #   - .mcp.json  : project-scoped, not a ~/.claude file. Personal/global MCP
    #                  servers live in ~/.claude.json, which holds OAuth/session
    #                  state and must never be committed.
    #   - skills/ (whole dir) : it's a 3-way mix (nix-store ast-grep +
    #                  cross-agent symlinks to ~/.agents/skills from the
    #                  agent-skills module + plugin dirs). Whole-dir symlinking
    #                  would clobber the agent-skills symlinks. INDIVIDUAL skills
    #                  are still owned here via per-skill symlinks (below) — those
    #                  manage one sub-path each and coexist with the mix.
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
      "claude/commands".source = svc "commands";
      "claude/hooks".source = svc "hooks";
      "claude/workflows".source = svc "workflows";
      "claude/themes".source = svc "themes";

      # ── Thermos (ported from cursor/plugins) ───────────────────────────────
      # Canonical content lives as a SELF-CONTAINED Claude plugin under
      # plugins/thermos/ (with .claude-plugin/plugin.json), catalogued by
      # plugins/.claude-plugin/marketplace.json. That makes it promotable: a
      # project's .claude/settings.json can point extraKnownMarketplaces at this
      # repo and enable `thermos` for the whole team — same artifact, scope
      # chosen by which settings.json enables it.
      #
      # For PERSONAL/global use we surface the plugin's pieces loosely so they
      # stay editable in place (cheap iteration), instead of loading the plugin
      # read-only via --plugin-dir:
      #   - skills: per-skill symlinks straight into the plugin dir (below).
      #   - agents: in-repo symlinks inside agents/ (which IS whole-dir
      #     symlinked) point at plugins/thermos/agents/* — keeping the plugin
      #     self-contained for publishing while still surfacing globally.
      "claude/skills/thermos".source = svc "plugins/thermos/skills/thermos";
      "claude/skills/thermo-nuclear-review".source = svc "plugins/thermos/skills/thermo-nuclear-review";
      "claude/skills/thermo-nuclear-code-quality-review".source = svc "plugins/thermos/skills/thermo-nuclear-code-quality-review";
    };

    # Note: The native installer places the binary at ~/.local/bin/claude
    # PATH for ~/.local/bin is managed globally in home.nix
  };
}
