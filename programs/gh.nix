# gh - GitHub's official command line tool
# https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix
#
# Note: The gh package is installed via 1password.nix shell plugins
# for biometric-authenticated credential management.
# This module configures gh settings and extensions.
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.gh = {
    enable = true;
    package = mkDefault pkgs.gh;

    settings = {
      # Aliases that allow you to create nicknames for gh commands
      aliases = {};

      # The editor that gh should run when creating issues, pull requests, etc.
      # If blank, will refer to environment.
      editor = mkDefault "";

      # The protocol to use when performing Git operations
      git_protocol = mkDefault "https";
    };

    # Enable gh as a Git credential helper
    gitCredentialHelper = {
      enable = mkDefault true;
    };

    # gh extensions
    # See: https://cli.github.com/manual/gh_extension
    extensions = [];
  };
}
