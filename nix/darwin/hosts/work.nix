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
  };

  # Path to user-specific home-manager module (relative to flake.nix)
  userModule = ./users/work.nix;

  # System architecture
  # Use "aarch64-darwin" for Apple Silicon, "x86_64-darwin" for Intel
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations)
  # Run `scutil --get LocalHostName` on the work machine to get this value
  hostname = "Work-MacBook"; # TODO: Update with actual hostname

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # Set to true if you need to run Intel-only brew packages
    enableRosetta = false;
  };
}
