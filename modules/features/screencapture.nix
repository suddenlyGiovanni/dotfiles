# Screencapture - macOS screenshot preferences
# https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.screencapture
#
# Configures screenshot file format (png, jpg, pdf, etc.), save location,
# drop shadow on window captures, and the post-capture thumbnail preview.
_: {
  flake.modules.darwin.screencapture = _: {
    system.defaults.screencapture = {
      disable-shadow = false; # Disable drop shadow border around screen captures. The default is false.
      location = null; # The filesystem path to which screen captures should be written. The default is "~/Desktop".
      show-thumbnail = true; # Show thumbnail after taking a screenshot. The default is true.
      type = "png"; # The file type to use for screenshots. Options are 'png', 'jpg', 'pdf', 'psd', 'gif', 'tga', 'tiff', 'bmp'. The default is 'png'.
    };
  };
}
