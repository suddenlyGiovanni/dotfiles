# Host-specific configuration for work MacBook Pro
# Machine: suddenlyGiovannis-MacBook-Work
{
  # User configuration for this host
  userConfig = {
    username = "giovanni.ravalico"; # Update with your work username if different
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/giovanni.ravalico"; # Update with your work home directory if different
    dotfilesPath = "/Users/giovanni.ravalico/Developer/dotfiles";
  };

  # Path to user-specific home-manager module (relative to hosts directory)
  userModule = ../../home/users/work.nix;

  # System architecture (Apple Silicon)
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations)
  hostname = "suddenlyGiovannis-MacBook-Work";

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # Set to true if you need to run Intel-only brew packages
    enableRosetta = false;

    # Work-only casks (not needed on personal machine)
    casks = [
      # Add work-specific applications here
      # Examples:
      # "slack"           # Team communication
      # "zoom"            # Video conferencing
      # "microsoft-teams" # Microsoft Teams
    ];
  };
}
