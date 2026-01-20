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
    # Move Python files to XDG directories
    sessionVariables = {
      # Python startup file (for interactive shell customization)
      PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";

      # Python REPL history
      PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    };

    # Ensure state directory exists for Python history
    activation.createPythonStateDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${config.xdg.stateHome}/python"
    '';
  };

  # ── Python Startup Configuration ────────────────────────────────────────────
  xdg.configFile."python/pythonrc".text = ''
    # Minimal pythonrc for XDG compliance
    # Enable tab completion
    import readline
    import rlcompleter
    readline.parse_and_bind("tab: complete")
  '';

  # ── Packages ──────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    uv # Extremely fast Python package installer and resolver, written in Rust
  ];
}
