# Menu Bar Clock - macOS menu bar time/date display preferences
# https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.menuExtraClock
#
# Configures the menu bar clock format: 24-hour vs 12-hour, date and
# day-of-week visibility, seconds display, and analog vs digital style.
_: {
  flake.modules.darwin.menuextra-clock = _: {
    system.defaults.menuExtraClock = {
      Show24Hour = true; # Show 24-hour time. The default is based on region settings.
      ShowDate = 0; # Show date in menu bar clock. 0 = "When Space Allows", 1 = "Always", 2 = "Never". Current system value: 0.
      ShowDayOfWeek = true; # Show the day of the week in menu bar clock. Current system value: true.
      ShowSeconds = false; # Show seconds in menu bar clock. The default is false.
      FlashDateSeparators = false; # Flash the date separators. The default is false.
      IsAnalog = false; # Show an analog clock instead of digital. The default is false.
    };
  };
}
