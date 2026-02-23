# Activity Monitor - macOS system monitoring utility preferences
# https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.ActivityMonitor
#
# Configures the Activity Monitor dock icon style, default view,
# sort column, and whether the main window opens on launch.
_: {
  flake.modules.darwin.activity-monitor = _: {
    system.defaults.ActivityMonitor = {
      IconType = 0; # Dock icon style: 0 = Application Icon, 2 = Network Usage, 3 = Disk Activity, 5 = CPU Usage, 6 = CPU History.
      OpenMainWindow = true; # Open the main window when opening Activity Monitor. Default is true.
      ShowCategory = 101; # Processes to show: 100 = All, 101 = All Hierarchically, 102 = My, 103 = System, 104 = Other Users, 105 = Active, 106 = Inactive, 107 = Windowed.
      SortColumn = "CPUUsage"; # Which column to sort the main activity page
      SortDirection = 0; # The sort direction of the sort column (0 is descending).
    };
  };
}
