# eza - A modern replacement for ls
# https://github.com/nix-community/home-manager/blob/master/modules/programs/eza.nix
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.eza = {
    enable = true;
    package = mkDefault pkgs.eza;

    # Shell integrations - derived from enabled shells
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    enableNushellIntegration = config.programs.nushell.enable;

    # Extra command line options passed to eza
    extraOptions = [];

    # Display icons next to file names (--icons argument)
    icons = mkDefault "auto";

    # List each file's Git status if tracked or ignored (--git argument)
    git = mkDefault true;
  };
}
