# Host-specific configuration for personal MacBook Air
# Machine: Giovannis-MacBook-Air
{
  # User configuration for this host
  userConfig = {
    username = "suddenlygiovanni";
    fullName = "Giovanni Ravalico";
    homeDirectory = "/Users/suddenlygiovanni";
    dotfilesPath = "/Users/suddenlygiovanni/dotfiles";
  };

  # Path to user-specific home-manager module (relative to hosts directory)
  userModule = ../users/personal.nix;

  # System architecture
  system = "aarch64-darwin";

  # Hostname (used in darwinConfigurations)
  hostname = "Giovannis-MacBook-Air";

  # Homebrew settings specific to this host
  homebrew = {
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = false;

    # Personal-only casks (not needed on work machine)
    casks = [
      "discord" # Voice and text chat software
      "transmission" # Open-source BitTorrent client
      "whatsapp" # Native desktop client for WhatsApp
    ];
  };
}
