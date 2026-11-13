# Rex - terminal workspace for people and agents (beta)
# https://www.superlogical.com/rex/docs/installation
# https://www.superlogical.com/rex/docs/customize/config
#
# The app itself is not installed from here: Rex Beta is a download with no
# Homebrew cask, and it updates itself. This module tracks what configures it.
#
#   ./config/         linked to ~/.config/rex. Rex reads init.lua there, and the
#                     Lua files beside it that init.lua loads with require.
#   rex               the CLI on PATH. It ships inside the app bundle, which
#                     puts it on no PATH by itself.
#   preferences       what the app's Settings window stores, in the macOS
#                     domain com.superlogical.rex.
#
# WHY AN OUT-OF-STORE LINK
#
# Rex never writes init.lua, so a store copy would work (ADR-009). The link is
# out-of-store so that an edit is live: `rex config reload` applies it with no
# switch, and `rex config check` validates it first. Rex does not watch the file.
#
# PREFERENCES
#
# A switch writes the values below, so a change made in the Settings window
# lasts until the next switch. To keep one, copy it here:
#
#   defaults read com.superlogical.rex
#
# Not tracked, on purpose: RexSync.servers (the servers this Mac connects to),
# Workspace.lastFocusedSession and Workspace.programActivitySeen (state).
{config, ...}: let
  inherit (config.dotfiles.user) dotfilesPath;
in {
  flake.modules.darwin.rex = {
    system.defaults.CustomUserPreferences."com.superlogical.rex" = {
      "Workspace.appIcon" = "default";
      "Workspace.interfaceStyle" = "blendTheme";
      "Workspace.darkThemeID" = "cobalt-foundry";
      "Workspace.lightThemeID" = "merino-light";
      "Workspace.paneDensity" = "comfortable";
      "Workspace.paneHeaderVisibility" = "always";
      "Workspace.inactivePaneFadeMode" = "both";
      "Workspace.notificationPosition" = "top-right";

      # Sparkle: check for updates and install them.
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
    };
  };

  flake.modules.homeManager.rex = {
    config,
    pkgs,
    ...
  }: let
    cli = "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
  in {
    xdg.configFile."rex".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/rex/config";

    # A wrapper, not a link: the path has spaces, and the message says what is
    # missing on a Mac that has no Rex yet.
    home.packages = [
      (pkgs.writeShellScriptBin "rex" ''
        if [ ! -x ${pkgs.lib.escapeShellArg cli} ]; then
          echo "rex: Rex Beta is not installed (https://www.superlogical.com/rex/docs/installation)" >&2
          exit 127
        fi
        exec ${pkgs.lib.escapeShellArg cli} "$@"
      '')
    ];
  };
}
