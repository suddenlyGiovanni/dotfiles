# Host-specific configuration for personal MacBook Air
# Machine: suddenlyGiovannis-MacBook-Personal
{
  # User configuration for this host
  userConfig = {
    username = "suddenlygiovanni";
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/suddenlygiovanni";
    dotfilesPath = "/Users/suddenlygiovanni/Developer/dotfiles";
  };

  # Path to home-manager module (relative to this file's location)
  userModule = ../home.nix;

  # System architecture
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations). This must match your Mac's LocalHostName.
  # To get the correct value for your machine, run: scutil --get LocalHostName
  hostname = "suddenlyGiovannis-MacBook-Personal";

  # Dock settings specific to this host
  dock = {
    persistent-apps = [
      "/Applications/Safari.app"
    ];
  };

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = false;

    # Personal-only casks (not needed on work machine)
    casks = [
      "transmission" # Open-source BitTorrent client
    ];
  };
}
