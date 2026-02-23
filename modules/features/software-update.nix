# Software Update - macOS automatic update preferences
# https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.SoftwareUpdate
#
# Configures automatic installation of macOS software updates.
# When enabled, updates are downloaded and installed without manual intervention.
_: {
  flake.modules.darwin.software-update = _: {
    system.defaults.SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = true; # Automatically install Mac OS software updates. Defaults to false.
    };
  };
}
