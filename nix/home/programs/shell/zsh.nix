# https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
{
  config,
  pkgs,
  userConfig,
  ...
}: {
  programs.zsh = {
    enable = true; # Z shell (Zsh)
    dotDir = "${config.xdg.configHome}/zsh"; # Use XDG-compliant location for zsh config files
    package = pkgs.zsh;
    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain --paging=never";
    };
    shellAliases = {
      ls = "eza";

      # List contents of directory using long format
      ll = "ls --all --long --icons --header --classify --group --group-directories-first --sort=type --time-style=default --hyperlink --git --git-repos";

      # List contents of directories in a tree-like format.
      tree = "ls --all --long --tree --level=2 --header --classify --group --git --icons --group-directories-first --sort=type --color-scale";

      ".." = "cd ..";

      cat = "bat --paging=never";

      bathelp = "bat --plain --language=help";

      switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}/nix/darwin";
    };
    enableCompletion = true; # Enable zsh completion.

    autosuggestion = {
      enable = true; # Enable zsh autosuggestions
      highlight = null; # Custom styles for autosuggestion highlighting.
      strategy = ["history"]; # an array that specifies how suggestions should be generated.
    };

    # Options related to commands history configuration.
    history = {
      append = true; # If set, zsh sessions will append their history list to the history file, rather than replace it.
      size = 10000; # Number of history lines to keep.
      path = "${config.xdg.dataHome}/zsh/history"; # History file location
    };

    # Initialization content
    initContent = ''
      printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'

      # Add any additional configurations here
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';

    # XDG compliance: ensure cache directory exists and use it for completion dump
    completionInit = ''
      # Ensure cache directory exists before compinit
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

      # Use XDG-compliant location for completion dump
      autoload -U compinit
      compinit -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
    '';

    # Plugins to source in {file}`.zshrc`.
    plugins = [
      #    {
      #      # will source zsh-autosuggestions.plugin.zsh
      #      name = "zsh-autosuggestions";
      #      src = pkgs.zsh-autosuggestions;
      #      file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      #    }
    ];
  };
}
