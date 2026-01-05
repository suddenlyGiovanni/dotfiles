# eza - A modern replacement for ls
# https://github.com/nix-community/home-manager/blob/master/modules/programs/eza.nix
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

    # Shell integrations
    enableBashIntegration = mkDefault true;
    enableZshIntegration = mkDefault true;
    enableFishIntegration = mkDefault true;
    enableNushellIntegration = mkDefault false;

    # Extra command line options passed to eza
    extraOptions = [];

    # Display icons next to file names (--icons argument)
    icons = mkDefault "auto";

    # List each file's Git status if tracked or ignored (--git argument)
    git = mkDefault true;
  };
}
