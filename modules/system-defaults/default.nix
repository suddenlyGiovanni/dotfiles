# macOS System Defaults
# This module imports all system preference modules
{
  imports = [
    ./activity-monitor.nix
    ./dock.nix
    ./finder.nix
    ./login-window.nix
    ./nsglobaldomain.nix
    ./software-update.nix
    ./spaces.nix
    ./trackpad.nix
    ./window-manager.nix
  ];
}
