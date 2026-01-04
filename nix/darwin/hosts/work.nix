# Host-specific configuration for work MacBook Pro
# Machine: suddenlyGiovannis-MacBook-Work
{
  # User configuration for this host
  userConfig = {
    username = "suddenlygiovanni";  # Same username across all machines
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/suddenlygiovanni";
    dotfilesPath = "/Users/suddenlygiovanni/Developer/dotfiles";
  };

  # Path to user-specific home-manager module (relative to hosts directory)
  # This is where work-specific git identity and configs live
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
