# macOS Trackpad Preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.trackpad
_: {
  system.defaults.trackpad = {
    Clicking = false; # Whether to enable trackpad tap to click. The default is false.
    Dragging = false; # Whether to enable tap-to-drag. The default is false.
    TrackpadRightClick = true; # Whether to enable trackpad right click.  The default is false.
    TrackpadThreeFingerDrag = false; # Whether to enable three finger drag. The default is false.
    ActuationStrength = 1; # 0 to enable Silent Clicking, 1 to disable. The default is 1.
    FirstClickThreshold = 1; # For normal click: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
    SecondClickThreshold = 1; # For force touch: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
    TrackpadThreeFingerTapGesture = 0; # 0 to disable three finger tap, 2 to trigger Look up & data detectors. The default is 2.
  };
}
