# Agent-agnostic skills (write-a-skill / find-skills / mattpocock & friends)
# https://github.com/mattpocock/skills
#
# ── DESIGN ───────────────────────────────────────────────────────────────────
#
# Skill content lives at `${dotfilesPath}/modules/features/agent-skills/skills/`,
# under git, edited freely by any coding agent (claude-code, codex, opencode,
# amp, gemini-cli, etc.). Home-manager only places a single out-of-store
# symlink from `~/.agents/skills` to that directory so every agent's skill
# loader resolves to the repo-tracked copy.
#
# Mutations to skills (create / edit / delete a `<name>/SKILL.md`) happen
# directly in `~/.agents/skills/<name>/` and land in the dotfiles working
# tree without a `darwin-rebuild switch`. The user then `git add`s and
# commits. New machines get the whole skill library for free on first
# activation.
#
# This is the same shape as `modules/features/zed/default.nix` — content in
# the repo, mkOutOfStoreSymlink into the home directory.
#
# ── RELATED ──────────────────────────────────────────────────────────────────
#
#   - claude-code/default.nix: Claude-specific config (CLAUDE.md, configDir,
#     and Claude-managed skills under ${configDir}/skills/). Those skills are
#     wired through `programs.claude-code.skills` (HM-symlinked from nix
#     store), NOT through ~/.agents/skills/.
#   - ~/.config/claude/skills/<name>: per-agent symlinks that point at
#     ../../../.agents/skills/<name>. Managed by Claude Code's skill loader,
#     not by home-manager.
#
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.agent-skills = {config, ...}: {
    home.file.".agents/skills".source =
      config.lib.file.mkOutOfStoreSymlink
      "${dotfilesPath}/modules/features/agent-skills/skills";
  };
}
