# Node.js runtime and package managers
# This module installs Node.js, pnpm, and configures XDG-compliant paths
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    ;
in {
  home = {
    # ── XDG Compliance ────────────────────────────────────────────────────────
    # Move npm/node files to XDG directories
    sessionVariables = {
      # npm - move cache and config to XDG locations
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

      # Node.js REPL history
      NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
    };

    # Ensure state directory exists for REPL history
    activation.createNodeStateDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.xdg.stateHome}/node"
    '';

    # ── Packages ──────────────────────────────────────────────────────────────
    packages = with pkgs; [
      nodejs_24 # Node.js JavaScript runtime
      pnpm # Fast, disk space efficient package manager
    ];
  };
}
