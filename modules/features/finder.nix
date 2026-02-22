# Finder preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.finder
_: {
  flake.modules.darwin.finder = _: {
    system.defaults.finder = {
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
      NewWindowTarget = "Home"; # Change the default location for new Finder windows. Options: "Computer", "OS volume", "Home", "Desktop", "Documents", "Recents", "iCloud Drive", "Other".
    };
  };
}
