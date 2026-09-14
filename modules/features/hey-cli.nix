# hey - Command-line interface for HEY email
# https://github.com/basecamp/hey-cli
#
# Installed from the upstream flake (not in nixpkgs). Its nixpkgs input follows
# ours, so it builds from source with our pinned Go toolchain (nix/go.nix needs
# go_1_27 — keep flake.lock new enough).
#
# The package ships bash/fish/zsh completions, so no `hey shell-completion install`.
# `hey upgrade` refuses on Nix installs by design; update with:
#   nix flake update hey-cli
#
# Agent integration (https://github.com/basecamp/hey-cli/blob/main/docs/agents.md)
# is declared here instead of `hey setup claude`, so the skill and MCP server are
# pinned to the same rev as the binary:
#   - skill: from the flake source, alongside ast-grep's in claude-code/default.nix
#   - MCP:   home-manager synthesizes a personal plugin at
#            ${configDir}/skills/claude-code-home-manager/.mcp.json, keeping it
#            out of the untracked ~/.claude.json. Tools surface as
#            mcp__plugin_hm_hey__*. The command is an absolute store path because
#            Claude.app starts from launchd, whose PATH lacks the HM profile.
#            Read-only: sending mail stays a deliberate `hey` CLI call.
# Don't run `hey setup` — it would install an unpinned, self-refreshing copy.
{inputs, ...}: {
  flake.modules.homeManager.hey-cli = {
    lib,
    pkgs,
    ...
  }: let
    hey = inputs.hey-cli.packages.${pkgs.stdenv.hostPlatform.system}.hey;
  in {
    home.packages = [hey];

    programs.claude-code = {
      skills.hey = "${inputs.hey-cli}/skills/hey";
      mcpServers.hey = {
        type = "stdio";
        command = lib.getExe hey;
        args = ["mcp" "--read-only"];
      };
    };
  };
}
