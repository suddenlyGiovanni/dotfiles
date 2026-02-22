# Login Window - macOS login screen preferences
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.loginwindow
#
# Configures the login screen display style (name/password vs user list),
# guest access, auto-login behavior, and visibility of power controls
# (shut down, sleep, restart) on the login screen and while logged in.
_: {
  flake.modules.darwin.login-window = _: {
    system.defaults.loginwindow = {
      SHOWFULLNAME = false; # Displays login window as a name and password field instead of a list of users. Default is false.
      autoLoginUser = "Off"; # Auto login the supplied user on boot. Default is Off.
      GuestEnabled = false; # Allow users to login to the machine as guests using the Guest account. Default is true.
      ShutDownDisabled = false; # Hides the Shut Down button on the login screen. Default is false.
      SleepDisabled = false; # Hides the Sleep button on the login screen. Default is false.
      RestartDisabled = false; # Hides the Restart button on the login screen. Default is false.
      ShutDownDisabledWhileLoggedIn = false; # Disables the "Shutdown" option when users are logged in. Default is false.
      PowerOffDisabledWhileLoggedIn = false; # If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
      RestartDisabledWhileLoggedIn = false; # Disables the "Restart" option when users are logged in. Default is false.
      DisableConsoleAccess = false; # Disables the ability for a user to access the console by typing ">console" for a username at the login window. Default is false.
    };
  };
}
