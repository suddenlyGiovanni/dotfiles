# gh - GitHub's official command line tool
# https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix
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
