# direnv - Load and unload environment variables depending on the current directory
# https://github.com/nix-community/home-manager/blob/master/modules/programs/direnv.nix
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
{
  config,
  lib,
  ...
}: let
  # Safe lookup for shell enable flags with fallback to false
  # This prevents evaluation failures if a shell module isn't imported
  shellEnabled = path: lib.attrByPath path false config;
in {
  programs.direnv = {
    enable = true;

    # Shell integrations - derived from enabled shells
    # Uses safe lookup with fallback to false if shell module isn't present
    enableBashIntegration = shellEnabled ["programs" "bash" "enable"];
    enableZshIntegration = shellEnabled ["programs" "zsh" "enable"];
    enableFishIntegration = shellEnabled ["programs" "fish" "enable"];
    enableNushellIntegration = shellEnabled ["programs" "nushell" "enable"];

    # Fast, persistent use_nix implementation for direnv
    nix-direnv.enable = true;
  };
}
