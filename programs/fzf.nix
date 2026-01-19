# fzf - A command-line fuzzy finder
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fzf.nix
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
  programs.fzf = {
    enable = true;
    package = mkDefault pkgs.fzf;

    # The command that gets executed as the default source for fzf
    defaultCommand = mkDefault null;

    # Extra command line options given to fzf by default
    defaultOptions = [];

    # CTRL-T: File widget configuration
    fileWidgetCommand = mkDefault null;
    fileWidgetOptions = [];

    # ALT-C: Change directory widget configuration
    changeDirWidgetCommand = mkDefault null;
    changeDirWidgetOptions = [];

    # CTRL-R: History widget configuration
    historyWidgetOptions = [];

    # Color scheme options added to FZF_DEFAULT_OPTS
    # See: https://github.com/junegunn/fzf/wiki/Color-schemes
    colors = {};

    # Shell integrations - derived from enabled shells
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
}
