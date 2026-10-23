# Node.js runtime and package managers
# This module installs Node.js, pnpm, and configures XDG-compliant paths
{inputs, ...}: {
  # ── Overlay: nodejs 26.12.1 ─────────────────────────────────────────────────
  # The 2026-10-21 security release (CVE-2026-111497, a Brotli decoder RCE, and
  # nine more) landed on nixpkgs master (NixOS/nixpkgs#576776) but not yet on
  # nixpkgs-unstable, which is on 26.12.0. Take nodejs-slim_latest from the
  # pinned master commit; drop this overlay and the nixpkgs-master input once
  # nixpkgs-unstable ships >= 26.12.1.
  flake.modules.darwin.nodejs = {
    nixpkgs.overlays = [
      (_final: prev: {
        inherit (inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}) nodejs-slim_latest;
      })
    ];
  };

  flake.modules.homeManager.nodejs = {
    config,
    lib,
    pkgs,
    ...
  }: {
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
        $DRY_RUN_CMD mkdir -p "${config.xdg.stateHome}/node"
      '';

      # ── Packages ──────────────────────────────────────────────────────────────
      packages = with pkgs; [
        nodejs-slim_latest # Node.js runtime (slim: no npm, pnpm handles installs)
        pnpm # Fast, disk space efficient package manager
      ];
    };
  };
}
