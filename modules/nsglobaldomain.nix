# NSGlobalDomain - Global macOS system preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.NSGlobalDomain
_: {
  system.defaults.NSGlobalDomain = {
    AppleShowAllFiles = true; # Whether to always show hidden files. The default is false.
    AppleFontSmoothing = null; # Sets the level of font smoothing (sub-pixel font rendering).
    AppleInterfaceStyle = null; # Set to 'Dark' to enable dark mode, or leave unset for normal mode.
    AppleInterfaceStyleSwitchesAutomatically = true; # Whether to automatically switch between light and dark mode. The default is false.
    ApplePressAndHoldEnabled = true; # Whether to enable the press-and-hold feature.  The default is true.
    AppleShowAllExtensions = true; # Whether to show all file extensions in Finder. The default is false.
    AppleShowScrollBars = "Automatic"; # When to show the scrollbars. Options are 'WhenScrolling', 'Automatic' and 'Always'.
    AppleScrollerPagingBehavior = false; # Jump to the spot that's clicked on the scroll bar. The default is false.
    NSAutomaticCapitalizationEnabled = false; # Whether to enable automatic capitalization.  The default is true.
    NSAutomaticInlinePredictionEnabled = true; # Whether to enable inline predictive text.  The default is true.
    NSAutomaticDashSubstitutionEnabled = false; # Whether to enable smart dash substitution.  The default is true.
    NSAutomaticPeriodSubstitutionEnabled = false; # Whether to enable smart period substitution.  The default is true.
    NSAutomaticQuoteSubstitutionEnabled = false; # Whether to enable smart quote substitution.  The default is true.
    NSAutomaticSpellingCorrectionEnabled = true; # Whether to enable automatic spelling correction.  The default is true.
    NSAutomaticWindowAnimationsEnabled = true; # Whether to animate opening and closing of windows and popovers.  The default is true.
    NSDisableAutomaticTermination = null; # Whether to disable the automatic termination of inactive apps.
    NSDocumentSaveNewDocumentsToCloud = true; # Whether to save new documents to iCloud by default.  The default is true.
    AppleWindowTabbingMode = null; # Sets the window tabbing when opening a new document: 'manual', 'always', or 'fullscreen'.  The default is 'fullscreen'.
    NSNavPanelExpandedStateForSaveMode = false; # Whether to use expanded save panel by default.  The default is false.
    NSTableViewDefaultSizeMode = null; # Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
    NSTextShowsControlCharacters = null; # Whether to display ASCII control characters using caret notation in standard text views. The default is false.
    NSUseAnimatedFocusRing = true; # Whether to enable the focus ring animation. The default is true.
    NSScrollAnimationEnabled = true; # Whether to enable smooth scrolling. The default is true.
    NSWindowResizeTime = null; # Sets the speed speed of window resizing.
    NSWindowShouldDragOnGesture = false; # Whether to enable moving window by holding anywhere on it like on Linux. The default is false.
    InitialKeyRepeat = null; # This sets how long you must hold down the key before it starts repeating.
    KeyRepeat = null; # This sets how fast it repeats once it starts.
    "com.apple.keyboard.fnState" = null; # Use F1, F2, etc. keys as standard function keys.
    "com.apple.mouse.tapBehavior" = null; # Configures the trackpad tap behavior.  Mode 1 enables tap to click.
    "com.apple.sound.beep.feedback" = 1; # Make a feedback sound when the system volume changed. This setting accepts 0 1
    "com.apple.trackpad.enableSecondaryClick" = true; # Whether to enable trackpad secondary click.  The default is true.
    "com.apple.trackpad.forceClick" = true; # Whether to enable trackpad force click.
    AppleMeasurementUnits = "Centimeters"; # Whether to use centimeters (metric) or inches (US, UK) as the measurement unit.  The default is based on region settings.
    AppleMetricUnits = 1; # Whether to use the metric system.  The default is based on region settings.
    AppleTemperatureUnit = "Celsius"; # Whether to use Celsius or Fahrenheit.  The default is based on region settings.
    AppleICUForce24HourTime = true; # Whether to use 24-hour or 12-hour time.  The default is based on region settings.
    _HIHideMenuBar = false; # Whether to autohide the menu bar.  The default is false.
  };
}
