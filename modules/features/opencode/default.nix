# opencode - open-source AI coding agent for the terminal
# https://opencode.ai/docs/config/
# https://github.com/anomalyco/opencode
#
# Binaries (CLI and desktop app): the upstream flake (input `opencode`), via the home-manager
# `programs.opencode` module's `package`. nixpkgs lags upstream releases; the input
# is pinned to a release tag in flake.nix (edit it, then `nix flake update opencode`).
# v2 tags have no GitHub Release; track them via the anomalyco/tap `opencode-v2`
# formula. Self-update is irrelevant for a store-managed binary and is turned off
# in opencode.json (`update`, v2's name for v1's `autoupdate`).
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
    upstream = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system};
    # v2.0.29: the CLI build scripts and electron-builder.config.ts import the root
    # script/native-arch.ts, but upstream's nix/node_modules.nix fileset omits
    # script/, so both builds fail with "Cannot find module". The file only imports
    # node:fs. Drop this once the fileset includes it.
    withNativeArch = drv:
      drv.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            install -Dm644 ${inputs.opencode}/script/native-arch.ts script/native-arch.ts
          '';
      });
    cliPackage = withNativeArch upstream.opencode;
    # Through v2.0.29 the desktop SDK still discovers service.json, whereas the prod
    # CLI registers service-prod.json. Patch only the desktop's bundled SDK; otherwise
    # it repeatedly starts contenders and never connects to the healthy service.
    # As of v2.0.29 both clients take the path from service-probe.ts's fallback().
    # desktop.nix inherits src from its `opencode` argument but not postPatch, so it
    # gets the patched CLI and the native-arch copy of its own.
    desktopPackage = (withNativeArch (upstream.opencode-desktop.override {opencode = cliPackage;})).overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace packages/client/src/service-probe.ts \
            --replace-fail '"service.json"' '"service-prod.json"'
        '';
    });
  in {
    programs.opencode = {
      enable = true;
      # Pinned to the 2.x line (input tag in flake.nix); bump the tag to upgrade.
      # v1.18.x needed a sigtool/cctools override for its darwin codesign step;
      # 2.x builds without it.
      package = cliPackage;
    };

    # Desktop app from the same pinned upstream flake input as the CLI, so both
    # track one version. The Homebrew cask lagged at 1.18.x. Both read the same
    # ~/.config/opencode.
    home.packages = [
      desktopPackage
    ];

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
