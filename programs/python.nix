# Python development tools and XDG compliance
# This module installs Python tools (uv) and configures XDG-compliant paths
{
  config,
  lib,
  pkgs,
  ...
}: {
  home = {
    # ── XDG Compliance ────────────────────────────────────────────────────────
    # Move Python REPL history to XDG state directory
    sessionVariables = {
      PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    };

    # Ensure state directory exists for Python history
    activation.createPythonStateDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.xdg.stateHome}/python"
    '';

    # ── Packages ──────────────────────────────────────────────────────────────
    packages = with pkgs; [
      uv # Extremely fast Python package installer and resolver, written in Rust
    ];
  };
}
