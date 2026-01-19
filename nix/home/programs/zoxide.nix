# zoxide - A smarter cd command that learns your habits
# https://github.com/nix-community/home-manager/blob/master/modules/programs/zoxide.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    ;
in {
  programs.zoxide = {
    enable = true;
    package = mkDefault pkgs.zoxide;

    # Options to pass to zoxide init
    options = [
      "--cmd cd" # Replace the cd command with zoxide
    ];

    # Shell integrations
    enableBashIntegration = mkDefault false;
    enableZshIntegration = mkDefault true;
    enableFishIntegration = mkDefault true;
    enableNushellIntegration = mkDefault true;
  };
}
