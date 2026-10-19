# Concrete host and user definitions.
# Sets the dotfiles.* options declared in options.nix.
_: {
  dotfiles = {
    user = {
      username = "suddenlygiovanni";
      fullName = "Giovanni Ravalico";
      homeDirectory = "/Users/suddenlygiovanni";
      dotfilesPath = "/Users/suddenlygiovanni/Developer/dotfiles";
    };

    hosts = {
      personal = {
        hostname = "suddenlyGiovannis-MacBook-Personal";
        hostRole = "personal";
        dock.persistent-apps = [
          "/Applications/Safari.app"
        ];
        homebrew.casks = [
          "pearcleaner" # Utility to uninstall apps and remove leftover files from old/uninstalled apps
          "transmission" # Open-source BitTorrent client
          "ungoogled-chromium" # Google Chromium, sans integration with Google
        ];
      };

      work = {
        hostname = "suddenlyGiovannis-MacBook-Work";
        hostRole = "work";
        homebrew.casks = [
          "bitwarden" # Vaultwarden desktop app: Touch ID unlock for bwbio (features/bitwarden)
          "claude" # Anthropic's official Claude AI desktop app
          "microsoft-teams" # Microsoft Teams
          "segger-jlink" # J-Link USB drivers for embedded dev (ESP32 serial)
          "zoom" # Video conferencing client
          {
            name = "google-chrome";
            args = {require_sha = false;};
          } # Web browser (no checksum published)
        ];
      };
    };
  };
}
