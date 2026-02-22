# macOS Trackpad Preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.trackpad
_: {
  flake.modules.darwin.trackpad = _: let
    # Shared gesture settings for both built-in and Bluetooth trackpads
    trackpadGestures = {
      TrackpadFiveFingerPinchGesture = 2; # Pinch with five fingers for Launchpad
      TrackpadFourFingerHorizSwipeGesture = 2; # Swipe between full-screen apps
      TrackpadFourFingerPinchGesture = 2; # Four finger pinch for Launchpad
      TrackpadFourFingerVertSwipeGesture = 2; # Four finger vertical swipe for Mission Control
      TrackpadThreeFingerHorizSwipeGesture = 2; # Swipe between pages
      TrackpadThreeFingerVertSwipeGesture = 2; # Three finger vertical for Mission Control/App Exposé
      TrackpadTwoFingerDoubleTapGesture = 1; # Smart zoom
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3; # Notification Center swipe
      TrackpadPinch = 1; # Pinch to zoom
      TrackpadRotate = 1; # Rotate
      TrackpadMomentumScroll = 1; # Momentum scrolling
      TrackpadHandResting = 1; # Palm rejection
      TrackpadHorizScroll = 1; # Horizontal scroll
      TrackpadScroll = 1; # Scroll
      USBMouseStopsTrackpad = 0; # Don't disable trackpad when mouse is connected
    };
  in {
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

    # Additional trackpad gesture settings via CustomUserPreferences
    # (These settings aren't available as typed nix-darwin options)
    system.defaults.CustomUserPreferences = {
      # Built-in trackpad multi-touch gestures
      "com.apple.AppleMultitouchTrackpad" = trackpadGestures;

      # Bluetooth trackpad - same settings for external trackpad
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpadGestures;
    };
  };
}
