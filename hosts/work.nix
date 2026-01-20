# Host-specific configuration for work MacBook Pro
# Machine: suddenlyGiovannis-MacBook-Work
{
  # User configuration for this host
  userConfig = {
    username = "suddenlygiovanni"; # Same username across all machines
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/suddenlygiovanni";
    dotfilesPath = "/Users/suddenlygiovanni/Developer/dotfiles";
  };

  # Path to home-manager module (relative to repository root, where flake.nix resolves imports)
  userModule = ./home.nix;

  # System architecture (Apple Silicon)
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations). This must match your Mac's LocalHostName.
  # To get the correct value for your machine, run: scutil --get LocalHostName
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
