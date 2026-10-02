# Coding agents — the shared domain
#
# Everything that is the same for every coding agent (claude-code, opencode,
# codex, amp, gemini-cli, …) is defined once, here, under git. Each agent's
# own module (claude-code/, opencode/) keeps only what is unique to that tool;
# this module is the only place that knows where each agent looks for the
# shared pieces.
#
#   agents/
#     default.nix   fan-out (this file)
#     AGENTS.md     global instructions, one file for every agent
#     skills/       skill library (https://github.com/mattpocock/skills & friends)
#
# ── INSTRUCTIONS ─────────────────────────────────────────────────────────────
#
# AGENTS.md is the single source of truth for the personal preferences that
# apply to every agent on this machine. Each agent's global-instructions path
# is an out-of-store symlink back to it, so editing any of them (by hand or by
# the agent) edits the one tracked file:
#
#   Claude Code  ${configDir}/CLAUDE.md        (Claude Code does not read AGENTS.md)
#   opencode     ~/.config/opencode/AGENTS.md  (opencode's native global rules file)
#
# Deliberately not `programs.claude-code.context` / `programs.opencode.context`:
# both render read-only nix-store copies, which defeats the single editable
# source. Add another agent by adding one more link below.
#
# ── SKILLS ───────────────────────────────────────────────────────────────────
#
# Skill content lives at `${dotfilesPath}/modules/features/agents/skills/`,
# edited freely by any coding agent. Home-manager only places a single
# out-of-store symlink from `~/.agents/skills` to that directory; opencode,
# codex, amp and friends read that path natively.
#
# Mutations to skills (create / edit / delete a `<name>/SKILL.md`) happen
# directly in `~/.agents/skills/<name>/` and land in the dotfiles working tree
# without a `darwin-rebuild switch`. The user then `git add`s and commits.
#
# Claude Code is the exception: its Claude-managed skills live under
# ${configDir}/skills/ (claude-code/default.nix, via `programs.claude-code.skills`
# from the nix store), plus per-agent symlinks to ../../../.agents/skills/<name>
# created by Claude Code's own skill loader, not home-manager.
#
# Same shape as `modules/features/zed/default.nix`: content in the repo,
# mkOutOfStoreSymlink into the home directory.
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.agents = {config, ...}: let
    agentsDir = "${dotfilesPath}/modules/features/agents";
    link = config.lib.file.mkOutOfStoreSymlink;
    agentsMd = link "${agentsDir}/AGENTS.md";
  in {
    home.file.".agents/skills".source = link "${agentsDir}/skills";

    xdg.configFile = {
      "claude/CLAUDE.md".source = agentsMd;
      "opencode/AGENTS.md".source = agentsMd;
    };
  };
}
