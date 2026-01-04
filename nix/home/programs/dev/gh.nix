# https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix
{pkgs, ...}: {
  programs.gh = {
    enable = true; # GitHub CLI tool
    package = pkgs.gh;
    settings = {
      aliases = {}; #   Aliases that allow you to create nicknames for gh commands.
      editor = ""; # The editor that gh should run when creating issues, pull requests, etc. If blank, will refer to environment.
      git_protocol = "https"; # The protocol to use when performing Git operations.
    };
    gitCredentialHelper = {
      enable = true; # the gh git credential helper
    };
    extensions = []; # gh extensions, see <https://cli.github.com/manual/gh_extension>.
  };
}
