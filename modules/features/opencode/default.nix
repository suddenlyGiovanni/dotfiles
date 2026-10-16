# opencode - open-source AI coding agent for the terminal
# https://opencode.ai/docs/config/
# https://github.com/anomalyco/opencode
#
# Binaries: vendor-managed, like claude-code/. opencode ships near-daily, and its
# desktop app and CLI meet over a background service whose registration file and
# port follow the build's release channel. Upstream's own Nix recipe builds a
# "prod" channel that no official client uses, and it broke outright at v2.0.29,
# so building from the flake meant carrying patches and lagging releases.
#   - Desktop: the `opencode-desktop` cask (darwin side below). It auto-updates
#     itself (greedyCasks in homebrew.nix lets activation upgrade it too) and
#     bundles its own CLI for its background service.
#   - CLI: the official v2 installer, once per machine:
#       curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
#     It installs ~/.opencode/bin/opencode, which opencode recognises as a curl
#     install and updates itself (`update: "auto"` in opencode.json). PATH comes
#     from home.sessionPath below, so the installer never edits shell rc files.
# The home-manager `programs.opencode` module is used purely for configuration;
# `package = null` opts out of package management.
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
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.darwin.opencode = _: {
    homebrew.casks = ["opencode-desktop"];
  };

  flake.modules.homeManager.opencode = {config, ...}: let
    svc = path:
      config.lib.file.mkOutOfStoreSymlink
      "${dotfilesPath}/modules/features/opencode/${path}";
  in {
    programs.opencode = {
      enable = true;
      # The official installer owns the binary; see the header.
      package = null;
    };

    home.sessionPath = ["${config.home.homeDirectory}/.opencode/bin"];

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
