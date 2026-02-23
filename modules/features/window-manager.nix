# Window Manager - macOS Stage Manager and window tiling preferences
# https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.WindowManager
#
# Configures Stage Manager (enable/disable, auto-hide, app grouping),
# click-to-show-desktop behavior, desktop icon/widget visibility, and
# window tiling options (margins, Option-key accelerator).
_: {
  flake.modules.darwin.window-manager = _: {
    system.defaults.WindowManager = {
      GloballyEnabled = false; # Enable Stage Manager; Stage Manager arranges your recent windows into a single strip for reduced clutter and quick access. Default is false.
      EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets. Default is true. false means "Only in Stage Manager" true means "Always"
      AutoHide = false; # Auto hide stage strip showing recent apps. Default is false.
      AppWindowGroupingBehavior = true; # Grouping strategy when showing windows from an application. false means "One at a time" true means "All at once"
      StandardHideDesktopIcons = false; # Hide items on desktop.
      HideDesktop = true; # Hide items in Stage Manager.
      StandardHideWidgets = false; # Hide widgets on desktop.
      StageManagerHideWidgets = false; # Hide widgets in Stage Manager.
      EnableTiledWindowMargins = true; # Enable margins between tiled windows. Default is null.
      EnableTilingOptionAccelerator = false; # Disable Option key accelerator for tiling. Default is null.
    };
  };
}
