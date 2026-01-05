# macOS System Defaults
# This module configures macOS system preferences (dock, finder, trackpad, etc.)
_: {
  system.defaults = {
    ActivityMonitor = {
      IconType = 0; # Change the icon in the dock when running.
      OpenMainWindow = true; # Open the main window when opening Activity Monitor. Default is true.
      ShowCategory = 101; # Change which processes to show.
      SortColumn = "CPUUsage"; # Which column to sort the main activity page
      SortDirection = 0; # The sort direction of the sort column (0 is descending).
    };

    NSGlobalDomain = {
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

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true; # Automatically install Mac OS software updates. Defaults to false.

    WindowManager = {
      GloballyEnabled = false; # Enable Stage Manager; Stage Manager arranges your recent windows into a single strip for reduced clutter and quick access. Default is false.
      EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets. Default is true. false means "Only in Stage Manager" true means "Always"
      AutoHide = false; # Auto hide stage strip showing recent apps. Default is false.
      AppWindowGroupingBehavior = true; # Grouping strategy when showing windows from an application. false means "One at a time" true means "All at once"
      StandardHideDesktopIcons = false; # Hide items on desktop.
      HideDesktop = null; # Hide items in Stage Manager.
      StandardHideWidgets = null; # Hide widgets on desktop.
      StageManagerHideWidgets = null; # Hide widgets in Stage Manager.
    };

    dock = {
      appswitcher-all-displays = false; # Whether to display the appswitcher on all displays or only the main one. The default is false.
      autohide = true; # Whether to automatically hide and show the dock. The default is false.
      autohide-delay = 0.24; # Sets the speed of the autohide delay.
      autohide-time-modifier = 1.0; # Sets the speed of the animation when hiding/showing the Dock.
      dashboard-in-overlay = false; # Whether to hide Dashboard as a Space. The default is false.
      enable-spring-load-actions-on-all-items = false; # Enable spring loading for all Dock items. The default is false.
      expose-animation-duration = 1.0; # Sets the speed of the Mission Control animations.
      expose-group-apps = true; # Whether to group windows by application in Mission Control's Exposé. The default is true.
      launchanim = true; # Animate opening applications from the Dock. The default is true.
      mineffect = "genie"; # Set the minimize/maximize window effect. The default is genie.
      minimize-to-application = false; # Whether to minimize windows into their application icon.  The default is false.
      mouse-over-hilite-stack = true; # Enable highlight hover effect for the grid view of a stack in the Dock.
      mru-spaces = false; # Whether to automatically rearrange spaces based on most recent use.  The default is true.
      orientation = "left"; # Position of the dock on screen.  The default is "bottom".
      persistent-apps = ["/Applications/Safari.app"]; # Persistent applications in the dock.
      persistent-others = null; # Persistent folders in the dock.
      show-process-indicators = true; # Show indicator lights for open applications in the Dock. The default is true.
      showhidden = true; # Whether to make icons of hidden applications translucent.  The default is false.
      show-recents = true; # Show recent applications in the dock. The default is true.
      static-only = false; # Show only open applications in the Dock. The default is false.
      tilesize = 48; # Size of the icons in the dock.  The default is 64.
      magnification = false; # Magnify icon on hover. The default is false.
      largesize = null; # Magnified icon size on hover. The default is 16.
      wvous-tl-corner = 1; # Hot corner action for top left corner.
      wvous-bl-corner = 1; # Hot corner action for bottom left corner.
      wvous-tr-corner = 1; # Hot corner action for top right corner.
      wvous-br-corner = 1; # Hot corner action for bottom right corner.
    };

    finder = {
      AppleShowAllFiles = true; # Whether to always show hidden files. The default is false.
      ShowStatusBar = true; # Show status bar at bottom of finder windows with item/disk space stats. The default is false.
      ShowPathbar = true; # Show path breadcrumbs in finder windows. The default is false.
      FXDefaultSearchScope = "SCcf"; # Change the default search scope. Use "SCcf" to default to current folder. The default is unset ("This Mac").
      FXPreferredViewStyle = "clmv"; # Change the default finder view. "icnv" = Icon view, "Nlsv" = List view, "clmv" = Column View, "Flwv" = Gallery View
      AppleShowAllExtensions = true; # Whether to always show file extensions.  The default is false.
      CreateDesktop = true; # Whether to show icons on the desktop or not. The default is true.
      QuitMenuItem = true; # Whether to allow quitting of the Finder.  The default is false.
      _FXShowPosixPathInTitle = true; # Whether to show the full POSIX filepath in the window title. The default is false.
      FXEnableExtensionChangeWarning = true; # Whether to show warnings when change the file extension of files.  The default is true.
    };

    loginwindow = {
      SHOWFULLNAME = false; # Displays login window as a name and password field instead of a list of users. Default is false.
      autoLoginUser = "Off"; # Auto login the supplied user on boot. Default is Off.
      GuestEnabled = false; # Allow users to login to the machine as guests using the Guest account. Default is true.
      ShutDownDisabled = false; # Hides the Shut Down button on the login screen. Default is false.
      SleepDisabled = false; # Hides the Sleep button on the login screen. Default is false.
      RestartDisabled = false; # Hides the Restart button on the login screen. Default is false.
      ShutDownDisabledWhileLoggedIn = false; # Disables the "Shutdown" option when users are logged in. Default is false.
      PowerOffDisabledWhileLoggedIn = false; # If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
      RestartDisabledWhileLoggedIn = false; # Disables the "Restart" option when users are logged in. Default is false.
      DisableConsoleAccess = false; # Disables the ability for a user to access the console by typing ">console" for a username at the login window. Default is false.
    };

    spaces.spans-displays = false; # Displays have separate Spaces. false = each physical display has a separate space (Mac default)

    trackpad = {
      Clicking = false; # Whether to enable trackpad tap to click. The default is false.
      Dragging = false; # Whether to enable tap-to-drag. The default is false.
      TrackpadRightClick = true; # Whether to enable trackpad right click.  The default is false.
      TrackpadThreeFingerDrag = false; # Whether to enable three finger drag. The default is false.
      ActuationStrength = 1; # 0 to enable Silent Clicking, 1 to disable. The default is 1.
      FirstClickThreshold = 1; # For normal click: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
      SecondClickThreshold = 1; # For force touch: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
      TrackpadThreeFingerTapGesture = 0; # 0 to disable three finger tap, 2 to trigger Look up & data detectors. The default is 2.
    };
  };
}
