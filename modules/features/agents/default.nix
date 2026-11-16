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
#     work/AGENTS.md  instructions for every work repository (work host only)
#     forks/AGENTS.md instructions for every fork or clone of someone else's project
#     personal/AGENTS.md  instructions for every personal project
#     skills/       global skills; kept empty on purpose. Claude Code ranks personal
#                   skills above project ones, so a global copy shadows the
#                   (newer) project version. Only add skills that are never
#                   project-scoped.
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
#   Delta        ~/.config/delta/AGENTS.md     (DELTA_CONFIG_DIR in delta-app/)
#
# Deliberately not `programs.claude-code.context` / `programs.opencode.context`:
# both render read-only nix-store copies, which defeats the single editable
# source. Add another agent by adding one more link below.
#
# Between the global file and a repository's own there is one more layer, by
# folder: Claude Code loads CLAUDE.md from every directory above the one it
# starts in, so ~/Developer/<folder>/CLAUDE.md reaches every repository in that
# folder and nothing else. Each folder's file is <folder>/AGENTS.md here, linked
# as CLAUDE.md and as AGENTS.md (for agents that read that name):
#
#   ~/Developer/work/   work host only. What every colleague should share
#                       belongs in infrastructure/developer instead.
#   ~/Developer/forks/  every host.
#   ~/Developer/personal/  every host.
#
# ~/Developer/dotfiles sits outside these folders and gets none of them.
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
  flake.modules.homeManager.agents = {
    config,
    lib,
    ...
  }: let
    agentsDir = "${dotfilesPath}/modules/features/agents";
    link = config.lib.file.mkOutOfStoreSymlink;
    agentsMd = link "${agentsDir}/AGENTS.md";
    folderInstructions = folder: let
      source = link "${agentsDir}/${folder}/AGENTS.md";
    in {
      "Developer/${folder}/CLAUDE.md".source = source;
      "Developer/${folder}/AGENTS.md".source = source;
    };
  in {
    home.file =
      {
        ".agents/skills".source = link "${agentsDir}/skills";
      }
      // folderInstructions "forks"
      // folderInstructions "personal"
      // lib.optionalAttrs config.dotfiles.isWorkHost (folderInstructions "work");

    xdg.configFile = {
      "claude/CLAUDE.md".source = agentsMd;
      "opencode/AGENTS.md".source = agentsMd;
      "delta/AGENTS.md".source = agentsMd;
    };
  };
}
