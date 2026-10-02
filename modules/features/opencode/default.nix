# opencode - open-source AI coding agent for the terminal
# https://opencode.ai/docs/config/
# https://github.com/anomalyco/opencode
#
# Binary: the upstream flake (input `opencode`), via the home-manager
# `programs.opencode` module's `package`. nixpkgs lags upstream releases; update
# with `nix flake update opencode`. opencode's `autoupdate` is irrelevant for a
# store-managed binary and is turned off in opencode.json.
#
# Config: same split as claude-code/. Everything opencode or its agents edit at
# runtime is an out-of-store symlink into this directory, so changes land in the
# dotfiles working tree. We bypass the module's `settings`/`tui`/`context`/
# `agents`/`commands`/`themes`/`tools` options (read-only store copies) and leave
# them unset; the module then writes nothing under ~/.config/opencode itself.
#
# XDG layout (opencode follows the base-dir spec natively, no env vars needed):
#   config  ~/.config/opencode/     <- this module
#   data    ~/.local/share/opencode/  auth.json, sessions (credentials: never tracked)
#   state   ~/.local/state/opencode/
#   cache   ~/.cache/opencode/
#
# Not linked, on purpose:
#   - AGENTS.md : shared with Claude Code, linked from agents/.
#   - skills/   : opencode reads ~/.agents/skills natively (agents/).
#   - node_modules, package.json, bun.lock: opencode installs plugin
#     dependencies there itself; machine-local, never tracked.
{
  inputs,
  config,
  ...
}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.opencode = {
    config,
    pkgs,
    ...
  }: let
    svc = path:
      config.lib.file.mkOutOfStoreSymlink
      "${dotfilesPath}/modules/features/opencode/${path}";
  in {
    programs.opencode = {
      enable = true;
      # v1.18.34's build script shells out to `codesign` on darwin, which the
      # sandbox lacks; nixpkgs' sigtool provides `codesign` and cctools the
      # `codesign_allocate` it spawns. Drop the override once upstream stops
      # requiring it.
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.darwin.sigtool pkgs.cctools];
      });
    };

    xdg.configFile = {
      "opencode/opencode.json".source = svc "opencode.json";
      "opencode/tui.json".source = svc "tui.json";
      # Whole-dir symlinks, tracked while empty via .gitkeep.
      "opencode/agents".source = svc "agents";
      "opencode/commands".source = svc "commands";
      "opencode/themes".source = svc "themes";
      "opencode/tools".source = svc "tools";
      "opencode/plugins".source = svc "plugins";
    };
  };
}
