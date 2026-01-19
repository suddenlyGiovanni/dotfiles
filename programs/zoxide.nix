# zoxide - A smarter cd command that learns your habits
# https://github.com/nix-community/home-manager/blob/master/modules/programs/zoxide.nix
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
  programs.zoxide = {
    enable = true;
    package = mkDefault pkgs.zoxide;

    # Options to pass to zoxide init
    options = [
      "--cmd cd" # Replace the cd command with zoxide
    ];

    # Shell integrations - derived from enabled shells
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    enableNushellIntegration = config.programs.nushell.enable;
  };
}
