# Session variables and XDG compliance
#
# This module sets environment variables to:
# 1. Make more tools respect XDG base directory specification
# 2. Set sensible defaults for common tools (EDITOR, PAGER, etc.)
# 3. Reduce home directory pollution
#
# Reference: https://wiki.archlinux.org/title/XDG_Base_Directory
{
  config,
  lib,
  ...
}: {
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
    # ===== Editors =====
    EDITOR = "nvim";
    VISUAL = "zed --wait";

    # ===== Pager =====
    PAGER = "less";
    MANPAGER = "less -R";
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

    # Note: VIMINIT removed - no vimrc exists and nvim is the primary editor

    # ===== Shell behavior =====

    # Colored man pages
    LESS_TERMCAP_mb = "\\033[1;31m"; # begin bold
    LESS_TERMCAP_md = "\\033[1;36m"; # begin blink
    LESS_TERMCAP_me = "\\033[0m"; # reset bold/blink
    LESS_TERMCAP_so = "\\033[01;44;33m"; # begin reverse video
    LESS_TERMCAP_se = "\\033[0m"; # reset reverse video
    LESS_TERMCAP_us = "\\033[1;32m"; # begin underline
    LESS_TERMCAP_ue = "\\033[0m"; # reset underline
  };
}
