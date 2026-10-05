# opencode - open-source AI coding agent for the terminal
# https://opencode.ai/docs/config/
# https://github.com/anomalyco/opencode
#
# Binary: the upstream flake (input `opencode`), via the home-manager
# `programs.opencode` module's `package`. nixpkgs lags upstream releases; the input
# is pinned to a release tag in flake.nix (edit it, then `nix flake update opencode`). opencode's `autoupdate` is irrelevant for a
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
  # Desktop app: Homebrew cask (auto-updating), like the Zed cask. The CLI
  # above stays Nix-managed; both read the same ~/.config/opencode.
  flake.modules.darwin.opencode = _: {
    homebrew.casks = ["opencode-desktop"];
  };

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
      # Pinned to the 2.x line (input tag in flake.nix); bump the tag to upgrade.
      # v1.18.x needed a sigtool/cctools override for its darwin codesign step;
      # 2.0.23 builds without it.
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
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
