# hunk - Review-first terminal diff viewer for agentic coders
# https://github.com/modem-dev/hunk
# https://github.com/modem-dev/hunk/blob/main/nix/README.md#home-manager
#
# Installed from the upstream flake via its Home Manager module (`programs.hunk`),
# which pins the package to the flake input — nixpkgs lags upstream releases.
# `hunk update` does not manage Nix installs; update with:
#   nix flake update hunk
#
# Integrations:
#   - git: hunk is the pager for `git diff` and `git show` only. Delta keeps the
#     jobs hunk can't do (see https://www.hunk.dev comparisons "hunk vs delta"):
#       - interactive.diffFilter (`git add -p`) needs a line-preserving filter;
#         hunk is a full-screen TUI, not a filter.
#       - pager.log / pager.blame: hunk only styles unified diffs; other text
#         falls through to plain `less -R`, losing delta's blame/log styling.
#     Not via programs.hunk.enableGitIntegration: it sets core.pager, which
#     delta's per-command pager.<cmd> entries would silently shadow. Instead,
#     force the two per-command keys over delta's. Git skips the pager when
#     stdout isn't a TTY, so agents and pipes still get plain diffs.
#   - Claude: the module's enableClaudeIntegration hardcodes ~/.claude/skills,
#     but our Claude config dir is XDG, so the hunk-review skill is registered
#     through programs.claude-code (same as hey-cli.nix) and stays pinned to
#     the installed binary's rev.
{inputs, ...}: {
  flake.modules.homeManager.hunk = {
    config,
    lib,
    ...
  }: let
    hunkPager = "${config.programs.hunk.package}/bin/hunk pager";
  in {
    imports = [inputs.hunk.homeManagerModules.default];

    programs.hunk.enable = true;

    programs.git.iniContent.pager = {
      diff = lib.mkForce hunkPager;
      show = lib.mkForce hunkPager;
    };

    programs.claude-code.skills.hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
  };
}
