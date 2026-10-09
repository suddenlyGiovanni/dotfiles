# Disk Arbitration - No "Disk Not Ejected Properly" notifications
#
# Unplugging a BLE stick or a J-Link probe otherwise raises the alert every time.
#
# diskarbitrationd runs as root and reads its preferences through SCPreferences
# from /Library/Preferences/SystemConfiguration/com.apple.DiskArbitration.diskarbitrationd.plist
# (apple-oss-distributions/DiskArbitration: DABase.h ___PREFS_DEFAULT_DIR,
# DASupport.m DAPreferenceListRefresh). A user-domain default
# (CustomUserPreferences) never reaches it, so activation writes the system plist.
# The daemon re-reads the file at start and when the console user changes
# (DAServer.c _DAConfigurationCallback): the setting takes effect at the next login.
_: {
  flake.modules.darwin.disk-arbitration = {
    system.activationScripts.postActivation.text = ''
      /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.DiskArbitration.diskarbitrationd \
        DADisableEjectNotification -bool true
    '';
  };
}
