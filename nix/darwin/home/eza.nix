# https://github.com/nix-community/home-manager/blob/master/modules/programs/eza.nix
{pkgs}: {
  enable = true; # eza, a modern replacement for {command}`ls`
  enableBashIntegration = true; # Bash integration
  enableZshIntegration = true; # Zsh integration
  enableFishIntegration = true; # Fish integration
  enableNushellIntegration = false; # Nushell integration
  extraOptions = []; # Extra command line options passed to eza.
  icons = null; # Display icons next to file names ({option}`--icons` argument).
  git = true; # List each file's Git status if tracked or ignored ({option}`--git` argument).
  package = pkgs.eza;
}
