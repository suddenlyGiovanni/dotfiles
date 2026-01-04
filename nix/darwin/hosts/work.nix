# Host-specific configuration for work MacBook
# Machine: Work-MacBook (update hostname after setup)
#
# TODO: Update these values when setting up your work machine:
# - hostname: Run `scutil --get LocalHostName` on the work machine
# - username: Your work account username
# - fullName: Your name as it appears in work systems
# - homeDirectory: Usually /Users/<username>
{
  # User configuration for this host
  userConfig = {
    username = "giovanni.ravalico"; # TODO: Update with your work username
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/giovanni.ravalico"; # TODO: Update with your work home directory
    dotfilesPath = "/Users/giovanni.ravalico/dotfiles"; # TODO: Update if dotfiles are cloned elsewhere
  };

  # Path to user-specific home-manager module (relative to hosts directory)
  userModule = ../users/work.nix;

  # System architecture (Apple Silicon)
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations)
  # Run `scutil --get LocalHostName` on the work machine to get this value
  hostname = "Work-MacBook"; # TODO: Update with actual hostname

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # Set to true if you need to run Intel-only brew packages
    enableRosetta = false;

    # Work-only casks (not needed on personal machine)
    # TODO: Update with your actual work applications
    casks = [
      # "slack"           # Team communication
      # "zoom"            # Video conferencing
      # "microsoft-teams" # Microsoft Teams
    ];
  };
}
