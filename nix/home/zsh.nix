# https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
{ config, pkgs }:
{
  enable = true; # Z shell (Zsh)
  package = pkgs.zsh;
  shellAliases = {
    ls = "eza";

    # List contents of directory using long format
    ll = "ls --all --long --icons --header --classify --group --group-directories-first --sort=type --time-style=default --hyperlink --git --git-repos";

    # List contents of directories in a tree-like format.
    tree = "ls --all --long --tree --level=2 --header --classify --group --git --icons --group-directories-first --sort=type --color-scale";

    ".." = "cd ..";

    switch = "darwin-rebuild switch --flake ~/dotfiles/nix/darwin";
  };
  enableCompletion = true; # Enable zsh completion.

  autosuggestion = {
    enable = true; # Enable zsh autosuggestions
    highlight = null; # Custom styles for autosuggestion highlighting.
    strategy = [ "history" ]; # an array that specifies how suggestions should be generated.
  };

  # Options related to commands history configuration.
  history = {
    append = false; # If set, zsh sessions will append their history list to the history file, rather than replace it.
    size = 10000; # Number of history lines to keep.
    path = "${config.xdg.dataHome}/zsh/history"; # History file location
  };

  initExtra = ''
    # Add any additional configurations here
    export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
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
}
