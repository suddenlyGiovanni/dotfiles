# CustomUserPreferences - Additional macOS settings not exposed via typed nix-darwin options
# These settings are applied via the CustomUserPreferences mechanism
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.CustomUserPreferences
#
# Note: Trackpad gesture settings are in trackpad.nix
_: {
  flake.modules.darwin.custom-preferences = _: {
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
  };
}
