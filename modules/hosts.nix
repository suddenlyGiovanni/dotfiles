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
          "transmission" # Open-source BitTorrent client
        ];
      };

      work = {
        hostname = "suddenlyGiovannis-MacBook-Work";
        hostRole = "work";
        homebrew.casks = [
          "claude" # Anthropic's official Claude AI desktop app
          "cursor" # AI-powered code editor
          "figma@beta" # Collaborative team software
          "gitbutler" # Git client for simultaneous branches
          "microsoft-teams" # Microsoft Teams
          "rustdesk"
          "segger-jlink" # J-Link USB drivers for embedded dev (ESP32 serial)
          "superwhisper" # Voice-to-text using AI
          {
            name = "google-chrome";
            args = {require_sha = false;};
          } # Web browser (no checksum published)
        ];
      };
    };
  };
}
