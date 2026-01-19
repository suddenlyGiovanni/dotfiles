# Session variables - Global editor and pager settings
# This module sets truly global environment variables that aren't tool-specific
#
# Note: Tool-specific XDG variables are co-located with their program modules:
# - bun.nix: BUN_INSTALL
# - nodejs.nix: NPM_CONFIG_*, NODE_REPL_HISTORY
# - rustup.nix: CARGO_HOME, RUSTUP_HOME
# - awscli.nix: AWS_CONFIG_FILE, AWS_SHARED_CREDENTIALS_FILE
# - docker.nix: DOCKER_CONFIG
# - python.nix: PYTHONSTARTUP, PYTHON_HISTORY
# - claude-code.nix: CLAUDE_CONFIG_DIR
#
# Reference: https://wiki.archlinux.org/title/XDG_Base_Directory
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
  # Ensure XDG state subdirectories exist for tools that write history files
  # (Tools without dedicated modules)
  home.activation.createXdgStateDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.stateHome}/less"
    mkdir -p "${config.xdg.stateHome}/sqlite"
  '';

  home.sessionVariables = {
    # ── Editors ─────────────────────────────────────────────────────────────
    EDITOR = mkDefault "vim";
    VISUAL = mkDefault "zed --wait";

    # ── Pager ───────────────────────────────────────────────────────────────
    PAGER = mkDefault "less";
    MANPAGER = mkDefault "less -R";

    # Move less history to XDG state
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";

    # ── 1Password SSH Agent ─────────────────────────────────────────────────
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

    # ── XDG compliance for tools without dedicated modules ──────────────────

    # GnuPG (system-wide security tool)
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";

    # Readline (inputrc) - pairs with config in xdg.nix
    INPUTRC = "${config.xdg.configHome}/readline/inputrc";

    # SQLite history
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # Wget (basic tool, rarely configured)
    WGETRC = "${config.xdg.configHome}/wget/wgetrc";

    # ── Tools not currently installed (kept for future use) ─────────────────
    # Uncomment when/if these tools are added

    # Fly.io
    # FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";

    # Kubernetes
    # KUBECONFIG = "${config.xdg.configHome}/kube/config";

    # Maven
    # MAVEN_OPTS = "-Dmaven.repo.local=${config.xdg.dataHome}/m2/repository";
  };
}
