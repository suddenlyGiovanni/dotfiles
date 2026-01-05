# zsh - The Z shell
# https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.zsh = {
    enable = true;
    package = mkDefault pkgs.zsh;

    # Use XDG-compliant location for zsh config files
    dotDir = "${config.xdg.configHome}/zsh";

    # Enable zsh completion
    enableCompletion = mkDefault true;

    # ── Aliases ─────────────────────────────────────────────────────────────

    # Global aliases (expanded anywhere in command line)
    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain --paging=never";
    };

    # Regular shell aliases
    shellAliases = {
      # Use eza as ls replacement
      ls = "eza";

      # List contents of directory using long format
      ll = "ls --all --long --icons --header --classify --group --group-directories-first --sort=type --time-style=default --hyperlink --git --git-repos";

      # List contents of directories in a tree-like format
      tree = "ls --all --long --tree --level=2 --header --classify --group --git --icons --group-directories-first --sort=type --color-scale";

      # Navigation
      ".." = "cd ..";

      # Use bat as cat replacement
      cat = "bat --paging=never";
      bathelp = "bat --plain --language=help";

      # Darwin rebuild shortcut
      switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}/nix/darwin";
    };

    # ── Autosuggestion ──────────────────────────────────────────────────────

    autosuggestion = {
      enable = mkDefault true;
      highlight = mkDefault null;
      strategy = ["history"];
    };

    # ── History ─────────────────────────────────────────────────────────────

    history = {
      # Append to history file rather than replace it
      append = true;
      # Number of history lines to keep
      size = 10000;
      # XDG-compliant history file location
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # ── Initialization ──────────────────────────────────────────────────────

    # XDG compliance: ensure cache directory exists and use it for completion dump
    completionInit = ''
      # Ensure cache directory exists before compinit
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

      # Add home-manager per-user profile to FPATH for completions (e.g., bun, gh)
      # This path contains completions from packages installed via home-manager
      if [[ -d "/etc/profiles/per-user/$USER/share/zsh/site-functions" ]]; then
        fpath=("/etc/profiles/per-user/$USER/share/zsh/site-functions" $fpath)
      fi

      # Use XDG-compliant location for completion dump
      autoload -U compinit
      compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
    '';

    # Main initialization content
    initContent = ''
      # Warp terminal integration
      printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'

      # Source nix-daemon if available
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';

    # ── Plugins ─────────────────────────────────────────────────────────────

    plugins = [
      # Example plugin configuration:
      # {
      #   name = "zsh-autosuggestions";
      #   src = pkgs.zsh-autosuggestions;
      #   file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      # }
    ];
  };
}
