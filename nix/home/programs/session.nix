# Session variables and XDG compliance
# This module sets environment variables to make tools respect XDG base directories
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
  # home-manager creates the base directories but not nested subdirs
  home.activation.createXdgStateDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.stateHome}/less"
    mkdir -p "${config.xdg.stateHome}/node"
    mkdir -p "${config.xdg.stateHome}/fly"
    mkdir -p "${config.xdg.stateHome}/python"
    mkdir -p "${config.xdg.stateHome}/sqlite"
  '';

  home.sessionVariables = {
    # ── Editors ─────────────────────────────────────────────────────────────
    EDITOR = mkDefault "nvim";
    VISUAL = mkDefault "zed --wait";

    # ── Pager ───────────────────────────────────────────────────────────────
    PAGER = mkDefault "less";
    MANPAGER = mkDefault "less -R";

    # Move less history to XDG state
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";

    # ===== 1Password SSH Agent =====
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

    # ===== XDG compliance for various tools =====

    # Cargo (Rust)
    CARGO_HOME = "${config.xdg.dataHome}/cargo";

    # Rustup
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";

    # npm - move cache and config to XDG locations
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

    # Node.js REPL history
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";

    # Bun
    BUN_INSTALL = "${config.xdg.dataHome}/bun";

    # Docker
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";

    # AWS CLI
    AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
    AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";

    # GnuPG
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";

    # Fly.io
    FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";

    # Readline (inputrc)
    INPUTRC = "${config.xdg.configHome}/readline/inputrc";

    # Wget
    WGETRC = "${config.xdg.configHome}/wget/wgetrc";

    # Kubernetes
    KUBECONFIG = "${config.xdg.configHome}/kube/config";

    # Maven
    MAVEN_OPTS = "-Dmaven.repo.local=${config.xdg.dataHome}/m2/repository";

    # Python
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";

    # SQLite
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # Claude Code - Force XDG compliance
    # Note: home-manager's programs.claude-code module uses hardcoded .claude/ paths
    # This env var overrides the default location to be XDG compliant
    CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";

    # Note: VIMINIT removed - no vimrc exists and nvim is the primary editor
  };
}
