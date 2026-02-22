# Software Update preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.SoftwareUpdate
_: {
  flake.modules.darwin.software-update = _: {
    system.defaults.SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = true; # Automatically install Mac OS software updates. Defaults to false.
    };
  };
}
