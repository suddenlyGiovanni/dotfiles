# Activity Monitor preferences
_: {
  flake.modules.darwin.activity-monitor = _: {
    system.defaults.ActivityMonitor = {
      IconType = 0; # Change the icon in the dock when running.
      OpenMainWindow = true; # Open the main window when opening Activity Monitor. Default is true.
      ShowCategory = 101; # Change which processes to show.
      SortColumn = "CPUUsage"; # Which column to sort the main activity page
      SortDirection = 0; # The sort direction of the sort column (0 is descending).
    };
  };
}
