# CustomUserPreferences - Additional macOS settings not exposed via typed nix-darwin options
# These settings are applied via the CustomUserPreferences mechanism
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.CustomUserPreferences
_: {
  system.defaults.CustomUserPreferences = {
    # Global Domain - Additional settings not in NSGlobalDomain typed options
    NSGlobalDomain = {
      # Week starts on Monday (1 = Sunday, 2 = Monday, etc.)
      AppleFirstWeekday = {
        gregorian = 2;
      };
      # Disable continuous spell checking in most apps
      NSAllowContinuousSpellChecking = false;
      # Whether to minimize windows on double-click (not a typed option)
      AppleMiniaturizeOnDoubleClick = false;
    };

    # Trackpad - Multi-touch gestures (com.apple.AppleMultitouchTrackpad)
    "com.apple.AppleMultitouchTrackpad" = {
      # Gesture settings (current system values)
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

    # Bluetooth Trackpad - Same settings for external trackpad
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      TrackpadFiveFingerPinchGesture = 2;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadPinch = 1;
      TrackpadRotate = 1;
      TrackpadMomentumScroll = 1;
      TrackpadHandResting = 1;
      TrackpadHorizScroll = 1;
      TrackpadScroll = 1;
      USBMouseStopsTrackpad = 0;
    };

    # Text Input Menu Agent (keyboard input sources indicator)
    "com.apple.TextInputMenuAgent" = {
      # Visibility handled by Control Center on modern macOS
    };

    # HIToolbox - Keyboard input sources
    "com.apple.HIToolbox" = {
      AppleFnUsageType = 0; # Fn key behavior: 0 = Do Nothing, 1 = Change Input Source, 2 = Show Emoji & Symbols, 3 = Start Dictation
    };

    # Screensaver - Lock behavior
    "com.apple.screensaver" = {
      tokenRemovalAction = 0; # What to do when removing login token: 0 = Do nothing
    };

    # Login window customization
    "com.apple.loginwindow" = {
      TALLogoutSavesState = false; # Don't reopen windows when logging back in
    };
  };
}
