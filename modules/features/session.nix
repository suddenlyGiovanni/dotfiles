# Session variables - Global editor and pager settings, and the login environment
# This module sets truly global environment variables that aren't tool-specific,
# and (darwin side) delivers the whole session environment to consumers that
# can't source POSIX scripts: nushell, the login shell, and GUI apps.
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
# ADR: docs/adr/002-xdg-compliance-session-variables.md, docs/adr/008-nushell-login-shell.md
{config, ...}: let
  user = config.dotfiles.user;
in {
  # ── Darwin: the login environment for non-POSIX consumers ─────────────────
  # POSIX shells build their environment from nix-darwin's set-environment
  # (/etc/zshenv, /etc/bashrc), Homebrew's shellenv and Home Manager's
  # hm-session-vars.sh. /etc/login-environment.sh sources the same scripts, in
  # fish's order (so PATH comes out the same), for what can't source them:
  # - nushell, the login shell, imports it in env.nu (nushell/env.nu)
  # - the launchd agent below exports it to GUI apps. They start from launchd,
  #   not a shell, and some (Claude.app) probe `$SHELL -l -i -c` with POSIX
  #   syntax that nu rejects. The export only reaches apps launched after it,
  #   so env.nu also answers Claude.app's probe for when the app opens first.
  flake.modules.darwin.session = {
    config,
    pkgs,
    ...
  }: let
    hmSessionVars = "${config.home-manager.users.${user.username}.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
    brew = "${config.homebrew.prefix}/bin/brew";

    loginEnvironment = pkgs.writeText "login-environment.sh" ''
      # nix-darwin system environment: PATH (nix profiles), NIX_*, XDG_*_DIRS, TERMINFO_DIRS
      if [ -z "''${__NIX_DARWIN_SET_ENVIRONMENT_DONE-}" ]; then
        . ${config.system.build.setEnvironment}
      fi

      # Homebrew (nix-homebrew)
      if [ -x ${brew} ]; then
        eval "$(${brew} shellenv sh)"
      fi

      # Home Manager session variables and sessionPath
      . ${hmSessionVars}

      # Determinate Nix puts its default profile first, as fish's loginShellInit does
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';
  in {
    environment.etc."login-environment.sh".source = loginEnvironment;

    # `launchctl setenv` reaches only processes launched afterwards and doesn't
    # survive logout, so this runs at every login (RunAtLoad). The script embeds
    # the environment's store path: a rebuild that changes it reloads the agent.
    launchd.user.agents.login-environment = {
      script = ''
        declare -A before
        while IFS= read -r -d "" kv; do
          before[''${kv%%=*}]=''${kv#*=}
        done < <(/usr/bin/env -0)

        . ${loginEnvironment}

        # Export what the login environment added or changed, minus include
        # guards (__HM_SESS_VARS_SOURCED, …) so shells still run their own setup,
        # and TERM, which set-environment re-exports (empty here).
        while IFS= read -r -d "" kv; do
          k=''${kv%%=*}
          v=''${kv#*=}
          [[ $k == __* || $k == TERM ]] && continue
          [[ -n ''${before[$k]+set} && ''${before[$k]} == "$v" ]] && continue
          /bin/launchctl setenv "$k" "$v"
        done < <(/usr/bin/env -0)
      '';
      serviceConfig.RunAtLoad = true;
    };
  };

  flake.modules.homeManager.session = {
    config,
    lib,
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
      $DRY_RUN_CMD mkdir -p "${config.xdg.stateHome}/less"
      $DRY_RUN_CMD mkdir -p "${config.xdg.stateHome}/sqlite"
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

      # ── XDG compliance for tools without dedicated modules ──────────────────
      # Note: SSH_AUTH_SOCK is configured in 1password.nix

      # Readline (inputrc) - pairs with config in xdg.nix
      INPUTRC = "${config.xdg.configHome}/readline/inputrc";

      # SQLite history
      SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

      # Wget config location (wget gracefully falls back to defaults if file doesn't exist)
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
  };
}
