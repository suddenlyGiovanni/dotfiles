# Host-specific configuration for personal MacBook Air
# Machine: Giovannis-MacBook-Air
{
  # User configuration for this host
  userConfig = {
    username = "suddenlygiovanni";
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/suddenlygiovanni";
  };

  # System architecture
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations)
  hostname = "Giovannis-MacBook-Air";

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = false;
  };
}
