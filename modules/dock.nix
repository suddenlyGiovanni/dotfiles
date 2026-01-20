# macOS Dock Preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.dock
{hostConfig, ...}: {
  system.defaults.dock = {
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
    persistent-apps = hostConfig.dock.persistent-apps or ["/Applications/Safari.app"]; # Persistent applications in the dock (configurable per-host).
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
}
