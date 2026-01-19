# Window Manager (Stage Manager) preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.WindowManager
_: {
  system.defaults.WindowManager = {
    GloballyEnabled = false; # Enable Stage Manager; Stage Manager arranges your recent windows into a single strip for reduced clutter and quick access. Default is false.
    EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets. Default is true. false means "Only in Stage Manager" true means "Always"
    AutoHide = false; # Auto hide stage strip showing recent apps. Default is false.
    AppWindowGroupingBehavior = true; # Grouping strategy when showing windows from an application. false means "One at a time" true means "All at once"
    StandardHideDesktopIcons = false; # Hide items on desktop.
    HideDesktop = null; # Hide items in Stage Manager.
    StandardHideWidgets = null; # Hide widgets on desktop.
    StageManagerHideWidgets = null; # Hide widgets in Stage Manager.
  };
}
